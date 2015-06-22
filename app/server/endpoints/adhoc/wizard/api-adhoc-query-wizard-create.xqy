xquery version "1.0-ml";

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace cfg = "http://www.marklogic.com/data-explore/lib/config"
  at "/server/lib/config.xqy";
import module namespace lib-adhoc-create = "http://marklogic.com/data-explore/lib/adhoc-create-lib" at "/server/lib/adhoc-create-lib.xqy";


let $create-form := map:get($cfg:getRequestFieldsMap, "queryText")
let $_ := if(map:contains($cfg:getRequestFieldsMap, "queryName")) then 
            lib-adhoc-create:create-edit-form-query($cfg:getRequestFieldsMap)
          else lib-adhoc-create:create-edit-view($cfg:getRequestFieldsMap)
let $message :=
    <div>
      <p>Created new query: { map:get($cfg:getRequestFieldsMap, "queryName") }</p>
      <div><a href="/adhoc">Return to Adhoc Query</a></div>
    </div>

return $message