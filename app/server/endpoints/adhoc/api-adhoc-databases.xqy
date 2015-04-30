xquery version "1.0-ml";
import module namespace lib-adhoc = "http://marklogic.com/data-explore/lib/adhoc-lib" at "/server/lib/adhoc-lib.xqy";
import module namespace to-json = "http://marklogic.com/data-explore/lib/to-json" at "/server/lib/to-json-lib.xqy";
(: Expected output 

    ['Documents','other',....]
:)

declare function local:get-json(){
    let $databases := lib-adhoc:get-databases()

    let $array-json := to-json:seq-to-array-json(to-json:string-sequence-to-json($databases))

    return $array-json
};

local:get-json()