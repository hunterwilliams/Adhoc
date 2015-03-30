xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";

declare function local:get-databases( $set-dbs )
{

  for $db  at $pos in xdmp:database-name(xdmp:databases())
  where
    fn:not(fn:contains($db, "Security"))
    and fn:not(fn:contains($db, "Modules"))
    and fn:not(fn:contains($db, "Trigger"))
    and fn:not(fn:contains($db, "JUnit"))
    and fn:not($db = ($cfg:ignoreDbs))
  order by $db ascending
  return
           <td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
              {element input {
                     attribute type {'checkbox'},
                     attribute name {'checkbox_'||$pos},
                     attribute id {'checkbox_'||$pos},
                     attribute value {$db},
                     if ( $db = $set-dbs ) then attribute checked {1} else () }
              }
              &nbsp;&nbsp;<label for='checkbox_{$pos}'>{$db}</label>
           </td>
};


declare function local:format-db-checkboxes( $tds )
{
  let $empties-to-add := 3 - (fn:count($tds) mod 3)
  let $l := ($tds, for $blank in (1 to $empties-to-add) return   <td>&nbsp;</td>)


  let $rows :=
    for $item at $pos in $l
    return if ($pos mod 3) then () else element tr {$l[$pos - 2],$l[$pos - 1], $item}

  return element table {  $rows }
};

(: let $type := xdmp:get-request-field("type")   :)
let $update-type := xdmp:get-request-field("updateType")
let $doc-type := xdmp:get-request-field("docType")
let $query := xdmp:get-request-field("query") 

let $root-element := if ( $update-type = "query") then "formQuery" else if ( $update-type = "view") then "view" else "bad-update-type"

let $current-query-databases :=
    xdmp:eval(
      'cts:search( /' || $root-element || ', cts:and-query((
        cts:element-value-query(xs:QName("documentType"), "' || $doc-type  || '"),
        cts:element-value-query(xs:QName("' || $update-type || 'Name"), "' || $query || '")
          ))   )/database/text()',
      (), <options xmlns="xdmp:eval">   <database>{xdmp:database("MLUM-Modules")}</database>  </options>)


let $form := 
    <form name="adhocupdatequerydb" action="/adhocupdatequerydb" method="post" >
      <h3>Databases {$update-type} can be used for:</h3>

      {local:format-db-checkboxes( local:get-databases($current-query-databases) )}


      <p><input type="button" value="{fn:concat("Update Dbs for ",$update-type," '",$query,"'")}"   
          onclick="var inputs=this.form.getElementsByTagName('input');
          for (var index = 0;  inputs.length > index; ++index)
            if (inputs[index].name.indexOf('checkbox') == 0 &amp;&amp; inputs[index].checked)
              {{ document.getElementById('db-list').value = document.getElementById('db-list').value + ',' + inputs[index].value;
                 inputs[index].checked = false;
                  }};  this.form.submit();"
           /></p>
      <input type="hidden" name="updateType" value="{$update-type}"/>
      <input type="hidden" name="query" value="{$query}"/>
      <input type="hidden" name="docType" value="{$doc-type}"/>
      <input type="hidden" id="db-list" name="db-list" value=""/>
    </form>

return render-view:display(fn:concat("Configure databases for ",$update-type," '",$query,"' (Document name: ",$doc-type,")"), $form)