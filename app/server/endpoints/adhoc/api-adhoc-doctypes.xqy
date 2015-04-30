xquery version "1.0-ml";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
(: Expected output 

    ['Documents','other',....]
:)
(: address.com:port/api/adhoc/:database :)
declare function local:get-json(){
	let $path := xdmp:get-original-url()
    let $tokens := fn:tokenize($path, "/")
    let $db 	:= $tokens[4]

    let $doctypes := lib-adhoc:get-doctypes($db)

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($doctypes))

    return $array-json
};



local:get-json()