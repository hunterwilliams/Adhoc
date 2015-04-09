xquery version "1.0-ml";

import module namespace render-view = "http://render-view" at "/server/view/render-view.xqy";

xdmp:logout(),
xdmp:set-response-code(200, "logged out")