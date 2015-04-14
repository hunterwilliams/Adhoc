xquery version "1.0-ml";
import module namespace la = "http://marklogic.com/ps/lib/adhoc" at "/server/lib/l-adhoc.xqy";
import module namespace to-json = "http://marklogic.com/ps/lib/to-json" at "/server/lib/l-to-json.xqy";
(: Expected output 

    ['Documents','other',....]
:)

declare function local:get-json(){
    let $databases := la:get-databases()

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($databases))

    return $array-json
};

local:get-json()