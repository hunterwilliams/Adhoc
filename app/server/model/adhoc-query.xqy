xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace cu = "http://check-user"
  at "/server/lib/check-user.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace searchyy = "http://marklogic.com/ps/lib/searchyy"
  at "/server/lib/search.xqy";


(: return HTML option elements based on all DBs on the server that pass some filter conditions :)
declare function local:get-databases()
{
  let $dbName := (map:get($cfg:getRequestFieldsMap, "database"), $cfg:defaultDb)[1]
  for $db in xdmp:database-name(xdmp:databases())
  where
    fn:not(fn:contains($db, "Security"))
    and fn:not(fn:contains($db, "Modules"))
    and fn:not(fn:contains($db, "Trigger"))
    and fn:not(fn:contains($db, "JUnit"))
    and fn:not($db = ($cfg:ignoreDbs))
  order by $db ascending
  return
    if ($db = $dbName) then
      <option selected="selected">{$db}</option>
    else
      <option>{$db}</option>
};

(:declare function local:build-facets($doc-type as xs:string) as element()*
{
  if ($doc-type = $cfg:EVENT-FACET-DOCTYPES) then
    for $f in $cfg:EVENT-FACETS/facet
    return
      if ($f/@type eq "faux-facet") then
        <constraint name="{ $f/@name }" xmlns="http://marklogic.com/appservices/search">
           <value>
              <attribute ns="" name="{ $f/@attribute }"/>
              <element ns="{ $f/@namespace }" name="{ $f/@element }"/>
           </value>
        </constraint>
      else
        <constraint name="{ $f/@name }" xmlns="http://marklogic.com/appservices/search">
          <range type="{ $f/@scalarType }">
            <element ns="{ $f/@namespace }" name="{ $f/@element }"/>
            <attribute name="{ $f/@attribute }"/>
          </range>
        </constraint>
  else
    ()
};:)

declare function local:xdmpEval($xquery as xs:string, $vars as item()*, $db as xs:string)
{

  xdmp:log("AdhocQuery evaluating: " || $xquery ),
  xdmp:eval(
    $xquery,
    $vars,
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};

declare function local:xdmpInvoke($module as xs:string, $params as item()*, $db as xs:string)
{
   xdmp:invoke(
    "/controller/search.xqy",
    $params,
    <options xmlns="xdmp:eval">
      <database>{ xdmp:database($db) }</database>
    </options>
  )
};

(: populate HTML input fields with previous values by setting the @value attribute :)
declare function local:retainValues( $element )
{
  typeswitch( $element )

  case element(input) return
    <input>
    {
      $element/@*,
      attribute value {map:get( $cfg:getRequestFieldsMap, $element/@name ) }
    }
    </input>

  case element() return
    element {node-name($element)}
    {
      $element/@*,
      $element/text()
      ,
      for $subelement in $element/element()
      return local:retainValues($subelement)
    }

  default return
    ()
};

declare function local:build-form($form)
{
  let $log :=
    if ($cfg:D) then
      for $key in map:keys($cfg:getRequestFieldsMap)
      return xdmp:log(text{ $key, " = ", map:get($cfg:getRequestFieldsMap, $key) })
    else
      ()
  let $form := local:retainValues($form)/element()
  let $pageNumber := (map:get( $cfg:getRequestFieldsMap, "pagenumber" ), "1")[1]
  let $selectedFacet := (map:get( $cfg:getRequestFieldsMap, "selectedfacet" ), "")[1]
  let $excludeDeleted :=
     if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
        ( map:get( $cfg:getRequestFieldsMap, "excludedeleted" )  = "1" )
     else
        fn:true()
  let $excludeVersions :=
     if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
         ( map:get( $cfg:getRequestFieldsMap, "excludeversions" )  = "1" )
     else
        fn:true()

  (: pass the form state (doc type, query name, view name) to JavaScript here by setting these
     global JS variables :)
  let $doctype2 := map:get($cfg:getRequestFieldsMap, "doctype2")
  let $query-name := map:get($cfg:getRequestFieldsMap, "queryName2")
  let $view-name := map:get($cfg:getRequestFieldsMap, "viewName")
  let $pagination-size := map:get($cfg:getRequestFieldsMap, "pagination-size")
  let $current-vals :=
    fn:string-join(
      (
        fn:concat("var lastDocType = '", $doctype2, "';"),
        fn:concat("var lastQueryName = '", $query-name, "';"),
        fn:concat("var lastViewName = '", $view-name, "';")
      )
    , "")

  let $script :=
    (
        '{
        '
        ,
        $current-vals
        ,
        '
          var checkDB = function(){
            var text = $("select[name=database]").val();
            var result =  getDBrecurse(text);
            console.log(text+" --> "+result);
            return result;
          };
          var getDBrecurse = function(text){
              var textToCompare = text.toLowerCase();    
              if (textToCompare.indexOf("modules") === -1){
                  if (textToCompare !== "cleanup-audit"){
                    if (textToCompare.indexOf("-") !== -1){
                        return text.substr(0,text.indexOf("-"));
                    } else if (textToCompare.search(/\d/) !== -1){
                        return getDBrecurse(text.replace(/\d+/g, ""));
                    } else
                    {
                      return text;
                    }
                  }
                  else
                  {
                    return text;
                  }
                                        
              }
              else {
                  return text;
              }
          }; 
          $("#deletequery").click(function(){
            $( "#deletequery-confirm" ).dialog({
              resizable: false,
              height:160,
              modal: true,
              buttons: {
                  "Delete query": function() {
                    $.ajax({
                      type: "GET",
                      url: "/delete-query",
                      data: {queryType: $("select[name=queryName2]").val(), documentType: $("select[name=doctype2]").val()},
                      success: function(xml) {  
                        setTimeout("location.reload(true);",750);
                      }
                    });
                  $(this).dialog("close");
                },
                Cancel: function() {
                  $(this).dialog("close");
                }
              }
            });
          });

          $("#deleteview").click(function(){
            $( "#deleteview-confirm" ).dialog({
              resizable: false,
              height:160,
              modal: true,
              buttons: {
                  "Delete view": function() {
                    $.ajax({
                      type: "GET",
                      url: "/delete-view",
                      data: {viewType: $("select[name=viewName]").val(), documentType: $("select[name=doctype2]").val()},
                      success: function(xml) {
                        setTimeout("location.reload(true);", 750);
                      }
                    });
                  $(this).dialog("close");
                },
                Cancel: function() {
                  $(this).dialog("close");
                }
              }
            });
          });

          $("#editquery").click(function(){
            var queryName;
            var documentType;
            var documentTypeText;
            var prefix;
            var names = [];
            var code;
                  
            $.ajax({
                type: "GET",
                url: "/get-editquery-params",
                data: {queryType: $("select[name=queryName2]").val(), documentType: $("select[name=doctype2]").val()},
                success: function(xml) {
                   $(xml).find("formQuery").each(function(){
                      queryName = $(this).find("queryName").text();
                      documentType = $(this).find("documentType");
                      documentTypeText = $(documentType).text();
                      prefix = $(documentType).attr("prefix");           
                      $(this).find("formLabel").each(function(){
                        names.push($(this).text());
                      })
                      code = $(this).find("code").text();
                    });
                }
            });
            
            $.ajax({
                type: "GET",
                url: "/adhoceditquery",
                success: function(data) {
                    $("#container").html(data);
                    $("input[name=queryName]").val(queryName);
                    $("input[name=rootElement]").val(documentTypeText);
                    var i = 1;
                    names.forEach(function(name) {
                       $("input[name=formLabel" + i + "]").val(name);
                       i++;
                    }); 
                    $("textarea[name=queryText]").val(code);
                    $("select[name=prefix]").val(prefix);
                }
            });
            
            return false; // to stop link
            
          });

          $("#editview").click(function(){
            var viewName;
            var documentType;
            var documentTypeText;
            var prefix;
            var columns = [];
            var expr = [];
            var code;
                  
            $.ajax({
                type: "GET",
                url: "/get-editview-params",
                data: {viewType: $("select[name=viewName]").val(), documentType: $("select[name=doctype2]").val()},
                success: function(xml) {
                   $(xml).find("view").each(function(){
                      viewName = $(this).find("viewName").text();
                      documentType = $(this).find("documentType");
                      documentTypeText = $(documentType).text();
                      prefix = $(documentType).attr("prefix");           
                      $(this).find("columns").each(function(){
                        $(this).find("column").each(function(){
                          columns.push($(this).attr("name"));
                          expr.push($(this).attr("expr"));
                        });
                      });
                    });
                }
            });
            
            $.ajax({
                type: "GET",
                url: "/adhoceditview",
                success: function(data) {
                    $("#container").html(data);
                    $("input[name=viewName]").val(viewName);
                    $("input[name=rootElement]").val(documentTypeText);
                    var exprCount = 0;
                    var i = 1;
                    columns.forEach(function(column) {
                       $("input[name=columnName" + i + "]").val(column);
                       $("input[name=columnExpr" + i + "]").val(expr[exprCount]);
                       exprCount++;
                       i++;
                    }); 
                }
            });
            
            return false; // to stop link
            
          });

          $("select[name=viewName]").change(function() {
            //alert("viewName changed");
            //clearcache();
            //$("#searchForm").submit();
          });

          $("select[name=queryName2]").change(function() {
            //alert("queryName2 changed");

            var docType = $("select[name=doctype2]").val();
            var queryName = $(this).val();

            $.ajax({
              type: "GET",
              url: "/get-form-query",
              data: {docType: docType, queryName: queryName},
              dataType: "xml",
              success: function(xml) {
                $(xml).find("formQuery").each(function(){
                  var i = 1;
                  $(this).find("formLabel").each(function(){
                    var label = $(this).text();
                    $("#label" + i).html(label + ":").show();
                    $("#input" + i).show();
                    i++;
                  });
                  // loop is in app.js. A way to avoid using less than character here.
                  loop(i, 15, function(j) {
                    $("#label" + j).hide();
                    $("#input" + j).hide();
                  });
                });
              }
            });
          });

          $("select[name=doctype2]").change(function() {
            //alert("doctype2 changed");

            var docType = $(this).val();

            $.ajax({
              type: "GET",
              url: "/get-query-names",
              data: {docType: docType, db: checkDB()},
              dataType: "xml",
              success: function(xml) {
                $("[name=queryName2]").html("");
                $(xml).find("queryNames").each(function(){
                  $(this).find("queryName").each(function(){
                    var name = $(this).text();
                    $("select[name=queryName2]").append(new Option(name, name));
                  })
                });
                if (lastQueryName.length != 0) {
                  if ($("select[name=queryName2] option[value=\""+lastQueryName+"\"]").length == 1) {
                    $("select[name=queryName2]").val(lastQueryName);
                  }
                }
                $("[name=queryName2]").trigger("change");
              }
            });

            $.ajax({
              type: "GET",
              url: "/get-view-names",
              data: {docType: docType, db: checkDB()},
              dataType: "xml",
              success: function(xml) {
                $("[name=viewName]").html("");
                $(xml).find("viewNames").each(function(){
                  $(this).find("viewName").each(function(){
                    var name = $(this).text();
                    $("select[name=viewName]").append(new Option(name, name));
                  })
                });
                if (lastViewName.length != 0) {
                  if ($("select[name=viewName] option[value=\""+lastViewName+"\"]").length == 1) {
                    $("select[name=viewName]").val(lastViewName);
                  }
                }
                $("[name=viewName]").trigger("change");
              }
            });

          });


          $.ajax({
            type: "GET",
            url: "/get-doctypes",
            data: {database: checkDB()},
            dataType: "xml",
            success: function(xml) {
              $("[name=doctype2]").html("");
              $(xml).find("docTypes").each(function(){
                $(this).find("docType").each(function(){
                  var name = $(this).text();
                  $("select[name=doctype2]").append(new Option(name, name));
                })
              });
              if (lastDocType.length != 0) {
                if ($("select[name=doctype2] option[value=\""+lastDocType+"\"]").length == 1) {
                  $("select[name=doctype2]").val(lastDocType);
                }
              }
              $("[name=doctype2]").trigger("change");
            }
          });


        $("select[name=database]").change(function() {

          $.ajax({
            type: "GET",
            url: "/get-doctypes",
            data: {database: checkDB()},
            dataType: "xml",
            success: function(xml) {
              $("[name=doctype2]").html("");
              $(xml).find("docTypes").each(function(){
                $(this).find("docType").each(function(){
                  var name = $(this).text();
                  $("select[name=doctype2]").append(new Option(name, name));
                })
              });
              if (lastDocType.length != 0) {
                if ($("select[name=doctype2] option[value=\""+lastDocType+"\"]").length == 1) {
                  $("select[name=doctype2]").val(lastDocType);
                }
              }
              $("[name=doctype2]").trigger("change");
            }
          });

        });

      });


      ')
  return
    <form id="searchForm"  name="searchForm"  action="/adhocquery"  method="post">
      <script>$().ready( function()
        {$script}
      </script>

      <div class="grid-container">
        <div class="col-md-4 col-md-offset-1">
            <div>
              <span>Database:</span>
              <select name="database">{ local:get-databases() }</select>
            </div>
            <br/>
            <div>
              <span>Document Name:</span>
              <select name="doctype2"><option value="d">doctype</option></select>
              <br/>&nbsp;<br/>
            </div>
            <div>
              <span>Query By:</span>
              <select name="queryName2"><option value="q">query</option></select>
              {
                if (cu:is-logged-in() and fn:not(cu:is-tester()) and cu:is-admin()) then
                  <span>
                    <br/>
                    <a id="editquery" href="#">Edit</a>&nbsp;&nbsp;&nbsp;
                    <a id="deletequery" href="#">Delete</a>&nbsp;&nbsp;&nbsp;
                    <a href="/adhocnewquery?type=query">New Query</a>&nbsp;&nbsp;&nbsp;
                    <a id="update_query_db" 
                    onclick=
                      "var selectedDocType = document.getElementById('searchForm').elements['doctype2'].value;
                       var selectedQuery = document.getElementById('searchForm').elements['queryName2'].value;
                       href = '/adhoc_update_query_db?updateType=query&amp;docType='+selectedDocType+'&amp;query='+selectedQuery"
                    >DBs</a><br/>&nbsp;<br/>
                  </span>
                else
                  ()
              }
            </div>
            <div>
              <span>View Name:</span>
              <select name="viewName"><option value="v">view</option></select>
              {
                if (cu:is-logged-in() and fn:not(cu:is-tester()) and cu:is-admin()) then
                  <span>
                    <br/>
                    <a id="editview" href="#">Edit</a>&nbsp;&nbsp;&nbsp;
                    <a id="deleteview" href="#">Delete</a>&nbsp;&nbsp;&nbsp;
                    <a href="/adhocnewview?type=view">New View</a>&nbsp;&nbsp;&nbsp;
                    <a id="update_view_db" 
                    onclick=
                      "var selectedDocType = document.getElementById('searchForm').elements['doctype2'].value;
                       var selectedQuery = document.getElementById('searchForm').elements['viewName'].value;
                       href = '/adhoc_update_query_db?updateType=view&amp;docType='+selectedDocType+'&amp;query='+selectedQuery"
                    >DBs</a><br/>&nbsp;<br/>
                  </span>
                else
                  ()
              }
            </div>
        </div>

        <div class="col-md-3">
          {$form}
        </div>

        <div class="col-md-3">
          <input type="checkbox" name="excludedeleted" value="1" >
          { if ( $excludeDeleted ) then attribute checked {"checked"}  else () }
          </input>
          <span>Exclude Deleted</span>
          <br/>
          <input type="checkbox" name="excludeversions" value="1" >
          { if ( $excludeVersions ) then attribute checked {"checked"}  else () }
          </input>
          <span>Exclude Versions</span>
          <br/>
          <span>Default Pagination</span>&nbsp;
          <select name="pagination-size">{
            if($pagination-size eq "10" or fn:empty($pagination-size)) then (
              <option selected="10">10</option>,
              <option value="100">100</option>)
            else (
              <option value="10">10</option>,
              <option selected="100">100</option>
            )}
          </select>
          <br/>
          <input type="hidden" name="go" value="1"/>
          <input type="hidden" id="pagenumber" name="pagenumber" value="{$pageNumber}"/>
          <input type="hidden" id="selectedfacet" name="selectedfacet" value="{$selectedFacet}"/>
          <input type="submit"  value="Submit" onclick="clearcache()" />
          <br/>
        </div>

        <div id="deletequery-confirm" title="" style="display:none;">
          <p>Delete the query?</p>
        </div>
 
         <div id="deleteview-confirm" title="" style="display:none;">
          <p>Delete the view?</p>
        </div>

      </div>
    </form>
};


declare function local:get-code-from-form-query(
  $doc-type as xs:string,
  $query-name as xs:string)
  as xs:string
{
  let $code := cfg:get-form-query($doc-type, $query-name)/fn:string(code)
  let $log := if ($cfg:D) then xdmp:log(text{ "get-code-from-form-query, $code = ", $code }) else ()
  return
    (: prevent XQuery injection attacks :)
    if (fn:contains($code, ";")) then
      fn:error((), "Form processing XQuery may not contain a semicolon")
    else if (fn:contains($code, "xdmp:eval")) then
      fn:error((), "Form processing XQuery may not contain xdmp:eval")
    else if (fn:contains($code, "xdmp:invoke")) then
      fn:error((), "Form processing XQuery may not contain xdmp:invoke")
    else
      $code
};

declare function local:get-result()
{
  let $doc-type := map:get($cfg:getRequestFieldsMap, "doctype2")
  let $database := map:get($cfg:getRequestFieldsMap, "database")
  let $query-name := map:get($cfg:getRequestFieldsMap, "queryName2")
  let $view-name := map:get($cfg:getRequestFieldsMap, "viewName")
  let $pagination-size := map:get($cfg:getRequestFieldsMap, "pagination-size")

  (: transaction-mode "query" causes XDMP-UPDATEFUNCTIONFROMQUERY on any update :)
  let $code-with-prolog :=
    $cfg:PROLOG ||  local:get-code-from-form-query($doc-type, $query-name)

  let $log := if ($cfg:D) then xdmp:log(text{ "local:get-result, $code-with-prolog = ", $code-with-prolog }) else ()

  let $excludeDeleted :=
    if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
      ( map:get( $cfg:getRequestFieldsMap, "excludedeleted" )  = "1" )
    else
      fn:true()

  let $excludeVersions :=
    if ( map:get( $cfg:getRequestFieldsMap, "go" ) = "1") then
      ( map:get( $cfg:getRequestFieldsMap, "excludeversions" )  = "1" )
    else
      fn:true()

  let $user-q :=
    local:xdmpEval(
      $code-with-prolog,
      (xs:QName("params"), $cfg:getRequestFieldsMap),
      $database
    )

  let $log := if ($cfg:D) then xdmp:log(text{ "local:get-result, $user-q = ", $user-q }) else ()


  let $searchParams := map:map()

  let $_ :=
    (
      map:put($searchParams, "id", map:get($cfg:getRequestFieldsMap, "id")),
      map:put($searchParams, "searchText", ""),
      map:put($searchParams, "page", "1"),
      map:put($searchParams, "facet", ()),
      map:put($searchParams, "pagenumber", map:get($cfg:getRequestFieldsMap, "pagenumber")),
      map:put($searchParams, "selectedfacet", map:get($cfg:getRequestFieldsMap, "selectedfacet")),

      map:put($searchParams, "database", $database),
      map:put($searchParams, "docType2", $doc-type),
      map:put($searchParams, "queryName2", $query-name),
      map:put($searchParams, "viewName", $view-name),
      map:put($searchParams, "pagination-size", $pagination-size)
      (:map:put($searchParams, "facets", local:build-facets($doc-type)):)
    )

  let $log :=
    if ($cfg:D) then
    (
      xdmp:log(text{ "$searchParams" })
      ,
      for $key in map:keys($searchParams)
      let $val := map:get($searchParams, $key)
      return
        xdmp:log(text{ $key, " = ",
          if ($val instance of element()*) then
            xdmp:describe($val, (), ())
          else
            fn:string($val)
        })
    )
    else
      ()

  return
    searchyy:search($searchParams,$database)
    (: local:xdmpEval( $cfg:searchQuery, (xs:QName("params"), $searchParams), map:get($cfg:getRequestFieldsMap,"database")) :)
};
(: -----------------------------------------------------------------------------------------------------------------------------------------------------------------------:)
(:                                   main                                                                                                                                                                       :)
(: -----------------------------------------------------------------------------------------------------------------------------------------------------------------------:)
(:  let $_ := xdmp:set-server-field("MarkLogic.DEBUG", fn:false()) :)

(: This is a template for the search form that is modified by JavaScript :)
let $form :=
  <form>
    <span id="label1">Label 1:</span>
    <input type="text" name="id1" id="id1"/>
    <br/><br/>
    {
      for $i in (2 to 15)
      return
        <div id="input{$i}" style="display:none">
          <span id="label{$i}">Label {$i}:</span>
          <input name="id{$i}" type="text"/>
        </div>
        
    }
    <br/>
    <div>
      <span>Word Search:</span>
      <input name="word" type="text"/>
    </div>
  </form>

let $form := local:build-form($form)

let $go := map:get( $cfg:getRequestFieldsMap, "go" )
let $html :=
  (
   $form,
   <br/>
   ,
   if ( $go eq "1" ) then
   (
     try
     {
       local:get-result()
     }
     catch( $err )
     {
       xdmp:log("Error Caught: " || xdmp:quote($err)), 
       <div>
         { xdmp:quote( $err ) }
       </div>
     }
   )
   else
     ()
  )

return render-view:display("Adhoc Query", $html)