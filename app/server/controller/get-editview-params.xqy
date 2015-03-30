xquery version "1.0-ml";

import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

let $view-type := xdmp:get-request-field("viewType")
let $document-type := xdmp:get-request-field("documentType")

return cfg:get-view($document-type, $view-type)