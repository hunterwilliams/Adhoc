xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace create-adhoc = "http://create-adhoc-documents"
  at "/server/controller/create-adhoc-documents.xqy";


let $form :=
  <form id="adhoceditview"  name="adhoceditview"  action="/adhoceditview"  method="post">

    <script>$().ready( function(){
    '{

      $("form").submit(function( event ) {
        var emptyinput = false;
        $("input").each(function() {
          if ($(this).val() == "") {
            if (!$(this).hasClass("adhocOptional")) {
              $(this).css("border", "1px solid red");
              emptyinput = true;
            }
            else {
              $(this).css("border", "1px solid black");
            }
          }
          else {
            $(this).css("border", "1px solid black");
          }
        });

        if (emptyinput) {
          event.preventDefault();
          alert("Please fill out all required fields before submitting. (View Name, Root Element and the first Column Name and Expression.");
        }
        else {
          return;
        }
      });

    });
    '}
    </script>

  <div>
    <h2>Edit Adhoc View</h2>
    <div>
      <div>
        <span>View Name:</span>
        <input type="text" name="viewName" size="20"/>
      </div><br/>
      <h3>Document Name</h3>
      <div>
        <span>Root Prefix:</span>
        <select id="prefix" name="prefix">
        {
          let $count := fn:count($cfg:NSBINDINGS)
          for $i in (1 to $count div 2)
          let $prefix := $cfg:NSBINDINGS[$i * 2 - 1]
          let $ns := $cfg:NSBINDINGS[$i * 2]
          let $label := fn:concat($prefix, " = ", $ns)
          return <option value="{ $prefix }">{ $label }</option>
        }
        </select>
      </div>
      <div>
        <span>Root Element:</span>
        <input type="text" name="rootElement" size="20"/>
      </div><br/>
      <h3>Database Name</h3>
      <div>
        <span>Database:</span>&nbsp;
        <select name="database">{ cfg:get-databases() }</select>
      </div><br/>      
      <h3>Columns</h3>
      <p>Column expression can be any XPath, starting with the root element
      (e.g. /test:document/a:subdoc) or any value expression
      that uses $doc as the document node of the search result. Example:
      fn:count($doc/test:document//a:name)
      </p>
      <div>
        <div>
          <span>Column Name:</span>
          <input name="columnName1" type="text"/>&nbsp;&nbsp;
          <span>Column Expression:</span>
          <input name="columnExpr1" type="text" size="75"/>
        </div>
        {
          for $i in (2 to 15)
          return
            <div>
              <span class="adhocOptional">Column Name:</span>
              <input class="adhocOptional" name="columnName{$i}" type="text"/>&nbsp;&nbsp;
              <span class="adhocOptional">Column Expression:</span>
              <input class="adhocOptional" name="columnExpr{$i}" type="text" size="75"/>
            </div>
        }
      </div>
    </div>
  </div>
  <input type="submit" id="submit" name="submit" value="Submit"/>

  </form>

return
  if (map:get($cfg:getRequestFieldsMap, "submit") = "Submit") then

    let $_ := create-adhoc:create-edit-view($cfg:getRequestFieldsMap)

    let $message :=
      <div>
        <p>Created new view: { map:get($cfg:getRequestFieldsMap, "viewName") }</p>
        <div><a href="/adhocquery">Return to Adhoc Query</a></div>
      </div>

    return render-view:display("Adhoc Edit View", $message)

  else
    render-view:display("Adhoc Edit View", $form)