xquery version "1.0-ml";
import module namespace la = "http://marklogic.com/ps/lib/adhoc" at "/server/lib/l-adhoc.xqy";
import module namespace to-json = "http://marklogic.com/ps/lib/to-json" at "/server/lib/l-to-json.xqy";
(: Expected output 

    ['Documents','other',....]
:)
(: address.com:port/api/adhoc/:database :)
declare function local:get-json(){
	let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= $tokens[4]

    let $doctypes := la:get-doctypes($db)

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($doctypes))

    return $array-json
};



local:get-json()