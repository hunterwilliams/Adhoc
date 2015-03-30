xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace create-adhoc = "http://create-adhoc-documents"
  at "/server/controller/create-adhoc-documents.xqy";


declare function local:get-labels($seq as xs:int*) as element(div)*
{
  for $i in $seq
  return
    <div>
      <span class="adhocOptional">Label {$i}:</span>
      <input class="adhocOptional" name="formLabel{$i}" type="text"/>
    </div>
};

let $form :=
  <form id="adhoceditform"  name="adhoceditform"  action="/adhoceditquery"  method="post">

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
          alert("Please fill out all fields before submitting.");
        }
        else {
          return;
        }
      });

      $("#toggleProlog").click(function () {
        var text =  $(this).text();
        if (text == "Show prolog") {
          $(this).text("Hide prolog");
          $("#prolog").css("display", "block");
        }
        else {
          $(this).text("Show prolog");
          $("#prolog").css("display", "none");
        }
      });

      $("#toggleExample").click(function () {
        var text =  $(this).text();
        if (text == "Show example query") {
          $(this).text("Hide example query");
          $("#example").css("display", "block");
        }
        else {
          $(this).text("Show example query");
          $("#example").css("display", "none");
        }
      });

    });
    '}
    </script>

    <h2>Edit Adhoc Form and Query</h2>

    <div>
      <span>Query By:</span>
      <input type="text" name="queryName" size="20"/>
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
    <h3>Form</h3>
    <div class="grid-container">
      <div class="grid-33">
        <div>
          <span>Label 1:</span>
          <input name="formLabel1" type="text"/>
        </div>
        { local:get-labels((2 to 5)) }
      </div>
      <div class="grid-33">
        { local:get-labels((6 to 10)) }
      </div>
      <div class="grid-33">
        { local:get-labels((11 to 15)) }
      </div>
    </div>
    <h3>Query</h3>
    <p><span id="toggleProlog"
      style="text-decoration:underline;color:blue;cursor:pointer;">Show prolog</span><br/>
      (The prolog is prepended to your query)</p>
    <div id="prolog" style="display:none">
      <pre>{ $cfg:PROLOG }</pre>
    </div>
    <p><span id="toggleExample"
      style="text-decoration:underline;color:blue;cursor:pointer;">Show example query</span></p>
    <div id="example" style="display:none">
      <pre>{ $cfg:EXAMPLE-QUERY }</pre>
    </div>
    <div id="adhoceditqueryname">
      <div>
        <textarea name="queryText" rows="15" cols="120">Form handling XQuery</textarea>
      </div>
    </div>

    <input type="submit" name="submit" value="Submit"/>

  </form>


return

  if (map:get($cfg:getRequestFieldsMap, "submit") = "Submit") then

    let $_ := create-adhoc:create-edit-form-query($cfg:getRequestFieldsMap)


    let $message :=
      <div>
        <p>Created new query: { map:get($cfg:getRequestFieldsMap, "queryName") }</p>
        <div><a href="/adhocquery">Return to Adhoc Query</a></div>
      </div>

    return render-view:display("Adhoc Edit Query", $message)

  else render-view:display("Adhoc Edit Query", $form) 