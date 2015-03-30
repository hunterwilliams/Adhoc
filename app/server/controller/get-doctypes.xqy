xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/ib/config.xqy";

let $db := xdmp:get-request-field("database")

let $names := cfg:get-document-types($db)
let $log := if ($cfg:D) then xdmp:log(text{ "get-doctypes ", fn:string-join($names, ",") }) else ()
return
  element docTypes {
    for $name in $names
    return element docType { $name }
  }

