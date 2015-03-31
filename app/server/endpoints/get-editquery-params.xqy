xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

let $query-type := xdmp:get-request-field("queryType")
let $document-type := xdmp:get-request-field("documentType")

return cfg:get-form-query($document-type, $query-type)

