xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";
import module namespace render-view = "http://render-view"
  at "/server/view/render-view.xqy";
import module namespace create-adhoc = "http://create-adhoc-documents"
  at "/server/controller/create-adhoc-documents.xqy";


let $create-form := map:get($cfg:getRequestFieldsMap, "queryText")
let $_ := if(fn:contains(map:keys($cfg:getRequestFieldsMap)[1], "formLabel")) then 
            create-adhoc:create-edit-form-query($cfg:getRequestFieldsMap)
          else create-adhoc:create-edit-view($cfg:getRequestFieldsMap)
let $message :=
    <div>
      <p>Created new query: { map:get($cfg:getRequestFieldsMap, "queryName") }</p>
      <div><a href="/adhocquery">Return to Adhoc Query</a></div>
    </div>

return render-view:display("Adhoc Create New Query", $message)