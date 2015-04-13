xquery version "1.0-ml";
import module namespace ld = "http://marklogic.com/ps/lib/detail" at "/server/lib/l-detail.xqy";

declare function local:get-xml(){
    let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= $tokens[4]
    let $first-part := fn:concat("/api/get-xml-doc/",$db,"/")
    let $uri 	:= fn:substring-after($path,$first-part)
    return 
    	if (fn:count($tokens) > 4) then
    		if (ld:database-exists($db)) then
                let $doc := ld:get-document($uri,$db)/element()
    			return (xdmp:set-response-content-type("text/xml"),$doc)
    		else
    			(xdmp:set-response-code(400,fn:concat("Invalid Database:",$db)))
        else
        	(xdmp:set-response-code(400,"URI Parameter count too low"))
};

local:get-xml()