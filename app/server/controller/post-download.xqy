(:
  Download content
:)

let $content := xdmp:get-request-field( "data" )
let $filename := xdmp:get-request-field( "filename", "download_file.xls" )
let $contentType := xdmp:get-request-field( "type", "application/x-download" )
return
(
  xdmp:set-response-content-type( $contentType ),
  xdmp:add-response-header("Content-Disposition", fn:concat("filename=", $filename)),
  xdmp:set-response-encoding("UTF-8"),
  $content
)