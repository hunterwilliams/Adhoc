xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";
import module namespace sm = "http://marklogic.com/ps/servicemetrics" at "/server/model/servicemetrics.xqy"; 

declare function local:download-from-db($uri, $db) {
      xdmp:eval('
        declare variable $uri as xs:string external;
        if($uri and fn:doc-available($uri)) then (
            fn:doc($uri)
        )
        else ()
        ', 
        (xs:QName("uri"),  $uri),
        <options xmlns="xdmp:eval">
          <database>{xdmp:database($db)}</database>
        </options>
      )
};

let $uri := $sm:CONF-URI
let $db := xdmp:get-request-field( "database" )
let $doc := 
    if ($uri and $db) then
        local:download-from-db($uri, $db)
    else ()
return
(
    xdmp:set-response-content-type(xdmp:uri-content-type($uri)),
    xdmp:add-response-header("Content-Disposition","attachment; filename='servicemetrics.xml'"),
    $doc
)
            

