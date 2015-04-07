xquery version "1.0-ml";

import module namespace rest="http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config" at "/server/lib/config.xqy";

import module namespace endpoints="http://example.com/ns/endpoints" at "/server/lib/endpoints.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $LOG_LEVEL := "finer";

declare option xdmp:mapping "false";

let $path := xdmp:get-request-path()

let $rewrite := rest:rewrite(endpoints:options())
let $uri :=
  if( $path eq "/favicon.ico" ) then
    "/images/favicon.ico"
  else if (empty($rewrite)) then
    let $path := fn:concat("/client",$path)
    let $exists :=
    xdmp:eval(
      'fn:exists(fn:doc("' || $path || '"))',
      (), <options xmlns="xdmp:eval">   <database>{xdmp:database($cfg:modules-db)}</database>  </options>)
    return 
    	if ($exists = fn:true()) then
    		$path
	    else if (fn:starts-with($path, "/client/app/") or fn:starts-with($path, "/client/bower_components/") 
	    	or fn:starts-with($path, "/client/components/") or fn:starts-with($path, "/client/css/")
	    	or fn:starts-with($path, "/client/fonts/") or fn:starts-with($path, "/client/images/")
	    	or fn:starts-with($path, "/client/js/")) then
	    	fn:error(xs:QName("RESTERROR"), "No Endpoint")
	    else
	    	$endpoints:DEFAULT
  else
    $rewrite

let $_ := xdmp:log(text{"REST controller: ", $path, " -> ", $uri} , $LOG_LEVEL)

return $uri