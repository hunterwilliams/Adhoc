xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";


let $doc-type := xdmp:get-request-field("docType")
let $database := xdmp:get-request-field("db")


let $names := cfg:get-view-names($doc-type,$database)
let $log := if ($cfg:D) then xdmp:log(text{ "get-view-names ", fn:string-join($names, ",") }) else ()
return
  element viewNames {
    for $name in $names
    return element viewName { $name }
  }

