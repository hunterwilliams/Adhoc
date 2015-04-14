xquery version "1.0-ml";

module namespace la = "http://marklogic.com/ps/lib/adhoc";
import module namespace cfg = "http://www.marklogic.com/ps/lib/config"
  at "/server/lib/config.xqy";

declare function la:get-databases() as xs:string*{
	for $db in xdmp:database-name(xdmp:databases())
  	where
	    fn:not(fn:contains($db, "Security"))
	    and fn:not(fn:contains($db, "Modules"))
	    and fn:not(fn:contains($db, "Trigger"))
	    and fn:not($db = ($cfg:ignoreDbs))
  	order by $db ascending
    return $db
};