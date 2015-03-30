xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

let $doc-type := xdmp:get-request-field("docType")
let $database := xdmp:get-request-field("db")

let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names doc-type := [ ", $doc-type, "]    $database :=  [",$database,"]" }) else ()

let $names := cfg:get-query-names($doc-type,$database)
let $log := if ($cfg:D) then xdmp:log(text{ "get-query-names ", fn:string-join($names, ",") }) else ()
return
  element queryNames {
    for $name in $names
    return element queryName { $name }
  }

