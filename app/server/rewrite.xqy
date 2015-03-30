xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";

import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $LOG_LEVEL := "finer";

declare option xdmp:mapping "false";

let $path := xdmp:get-request-path()

let $rewrite := rest:rewrite(endpoints:options())
let $uri :=
  if( $path eq "/favicon.ico" ) then
    "/images/favicon.ico"
  else if( fn:starts-with($path, "/xml/") and fn:ends-with($path, ".xml") ) then
    $path
  else if( fn:starts-with($path, "/js/") or fn:starts-with($path, "/fonts/") or fn:starts-with($path,"/css/"), fn:starts-with($path,"/images/")) then
    fn:concat("/client/",$path)
  else if (empty($rewrite)) then
    fn:error(xs:QName("RESTERROR"), "No Endpoint")
  else
    $rewrite

let $_ := xdmp:log(text{"REST controller: ", $path, " -> ", $uri} , $LOG_LEVEL)

return $uri