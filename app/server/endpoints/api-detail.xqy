xquery version "1.0-ml";
import module namespace ld = "http://marklogic.com/ps/lib/detail" at "/server/lib/l-detail.xqy";
import module namespace to-json = "http://marklogic.com/ps/lib/to-json" at "/server/lib/l-to-json.xqy";
(: Expected output 

	{type:'DocumentType',permissions:[{'role':'test','method':'read'}],collections:['a','b'],text:'<root></root>',
      related:[
        {
          type:'Type A', items:[{uri:'abc.html',db:'Documents'}]
        }
      ]
    };

	:)
declare function local:db-exists($database as xs:string){
	try {
		let $x := xdmp:database($database)
		return fn:true()
	}
	catch ($err){
		fn:false()
	}
};

declare function local:get-json($uri as xs:string, $db as xs:string){
	let $doc 		 :=  ld:get-document($uri,$db)/element()
	let $doctype 	 := fn:local-name( $doc )
    let $temp-collections := () (:ld:get-collections($uri,$db):)
    let $collections := for $c in $temp-collections return <collection>{$c}</collection>
	let $permissions := ld:get-permissions($uri,$db)
	let $related 	 := ()
    let $xml := <output><type>{$doctype}</type>{$collections}{$permissions}<text>{xdmp:quote($doc)}</text></output>

	return to-json:to-json($xml)
};

declare function local:get-details(){
    let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= $tokens[4]
    let $first-part := fn:concat("/api/detail/",$db,"/")
    let $uri 	:= fn:substring-after($path,$first-part)
    return 
    	if (fn:count($tokens) > 4) then
    		if (local:db-exists($db)) then
    			(xdmp:set-response-code(200,"Success"),local:get-json($uri,$db))
    		else
    			(xdmp:set-response-code(400,fn:concat("Invalid Database:",$db)))
        else
        	(xdmp:set-response-code(400,"URI Parameter count too low"))
};

local:get-details()