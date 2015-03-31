xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

let $doc-type := xdmp:get-request-field("docType")
let $query-name := xdmp:get-request-field("queryName")

return cfg:get-form-query($doc-type, $query-name)


