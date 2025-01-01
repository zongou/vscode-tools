#!/bin/sh
set -eu

msg() { printf '%s\n' "$*" >&2; }

commitId=$(awk -F'"' '{print $2}' "${HOME}/.vscode/cli/serve-web/lru.json" | head -n 1)
msg "Patching: commitId=${commitId}"
cd "${HOME}/.vscode/cli/serve-web/${commitId}/out/vs/code/browser/workbench"

js="workbench.js"
html="workbench.html"

msg "Backup original files"
for f in "${js}" "${html}"; do
    if ! test -f $f.bak; then
        cp $f $f.bak
    fi
done

msg "Restore original files"
cp "${js}".bak "${js}"
cp "${html}".bak "${html}"

msg "Patching: fix keyboard popping up when scrolling"
## (zs.Contextmenu,l.initialTarget)
EventType=$(grep -Eo '\(\w+.Contextmenu,\w+\.initialTarget\)' "${js}" | grep -Eo '\w+\.Contextmenu' | cut -d'.' -f1)
# echo EventType="${EventType}"
test -n "${EventType}"
var=eventType

sed -E -i "s^(;this.\\w\\(e,m,s,Math.abs\\(g\\)/f,g>0\\?1:-1,u,Math.abs\\(p\\)/f,p>0\\?1:-1,d\\))^\1,this.${var}=${EventType}.Change^g" "${js}"
sed -E -i "s^(\\[a\\.identifier\\]\\}this.h&&\\()(\\w.preventDefault\\(\\),)^\\1this.${var}!==${EventType}.Change\\&\\&\\2this.${var}=void 0,^g" "${js}"
## ;this.F(e,m,s,Math.abs(g)/f,g>0?1:-1,u,Math.abs(p)/f,p>0?1:-1,d),this.xxx=zs.Change}this.D(this.C(zs.End,l.initialTarget)),delete this.r[a.identifier]}this.h&&(this.xxx!==zs.Change&&t.preventDefault(),this.xxx=void 0,t.stopPropagation(),this.h=!1)}
grep -E -o -q ';this.\w\(e,m,s,Math\.abs\(g\)/f,g>0\?1:-1,u,Math\.abs\(p\)/f,p>0\?1:-1,d\),this\.eventType=\w+\.Change\}this\.\w\(this\.\w+\(\w+\.End,l\.initialTarget\)\),delete this\.\w\[\w\.identifier\]\}this\.\w&&\(this\.eventType!==\w+\.Change&&t\.preventDefault\(\),this\.eventType=void 0,\w\.stopPropagation\(\),this\.\w=!1\)\}' "${js}"

viewportInteractiveWidget=resizes-content
msg "Patching: add html viewport content interactive-widget=${viewportInteractiveWidget}"
sed -E -i "s/(<meta name=\"viewport\" )(content=.+)(>$)/\1content=\"width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, interactive-widget=resizes-content\"\3/" "${html}"
## <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, interactive-widget=resizes-content">
grep -E -o -q "<meta name=\"viewport\" content=\".+, interactive-widget=${viewportInteractiveWidget}\">$" "${html}"

commandPanelWidth=.80
msg "Patching: change command panel width to ${commandPanelWidth}"
sed -E -i "s^(Math.min\\(this\\.\\w\\.width\*)(\\.[0-9]+)^\\1${commandPanelWidth}^" "${js}"
grep -E -o -q '(Math\.min\(this\.\w\.width\*)(\.[0-9]+)' "${js}"

msg "Patching: fix context menu for android"
## ,$dt=!!(hw&&hw.indexOf("Android")>=0),
isAndroid=$(grep -Eo ',.{1,5}=!!\(\w+&&\w+.\.indexOf\("Android"\)>=0\)' "${js}" | cut -d= -f1 | sed s/,//)
test -n "${isAndroid}"
# echo isAndroid="${isAndroid}"

sed -E -i "s^(if\\(this\\.\\w\\.canRelayout===!1&&!\\(\\w+&&\\w+\\.pointerEvents\\))(\\))^\1\&\&!${isAndroid}\2^" "${js}"
## (this.j.canRelayout===!1&&!(Il&&hg.pointerEvents)&&!$dt){this.hide()
grep -E -o -q '\(this\.\w\.canRelayout===!1&&!\(\w+&&\w+\.pointerEvents\)&&!.{1,3}\)\{this\.hide\(\)' "${js}"

sed -E -i "s^(\\{this\\.\\$&&\\!\\(Il&&hg\\.pointerEvents\\))(&&this\\.\\$\\.blur\\(\\)\\})^\1\&\&!${isAndroid}\2^" "${js}"
## {this.$&&!(Il&&hg.pointerEvents)&&!$dt&&this.$.blur()}
grep -E -o -q '\(\)=>\{this\..{1,3}!\(\w+&&\w+\.pointerEvents\)&&!.{1,3}&&this\..\.blur\(\)' "${js}"

sed -E -i "s^(showContextView\\(\w,\w,\w\\)\\{let \w;)(.+)(,this.b.show\\(\\w\\))^\\1${isAndroid}?this.b.setContainer(this.c.activeContainer,1):(\\2)\\3^" "${js}"
## showContextView(e,t,s){let n;$dt?this.b.setContainer(this.c.activeContainer,1):(t?t===this.c.getContainer(Ie(t))?n=1:s?n=3:n=2:n=1,this.b.setContainer(t??this.c.activeContainer,n)),this.b.show(e);
grep -E -o -q 'showContextView\(\w,\w,\w\)\{let \w;.{1,3}\?this\.\w.setContainer\(this\.\w.activeContainer,1\):\(' "${js}"

msg "Patching: change default configuration keyboard.dispatch to 'keyCode' for android"
sed -E -i "s^(,properties:\\{\"keyboard\\.dispatch\":\\{scope:1,type:\"string\",enum:\\[\"code\",\"keyCode\"\\],default:)(\"code\")^\\1${isAndroid}?\"keyCode\":\"code\"^" "${js}"
## ,properties:{"keyboard.dispatch":{scope:1,type:"string",enum:["code","keyCode"],default:$dt?"keyCode":"code",
grep -E -o -q ',properties:\{"keyboard\.dispatch":\{scope:1,type:"string",enum:\["code","keyCode"\],default:.{1,3}\?"keyCode":"code",' "${js}"

msg "Patching: fix actionWidget for android"
sed -E -i 's^(,r\.add\(q\(c,)(ie\.MOUSE_DOWN)(,\(\)=>c\.remove\(\)\)\))(;)^\1\2\3\1"touchstart"\3\1"touchmove"\3\4^g' "${js}"
# ;c.classList.add("context-view-pointerBlock"),r.add(q(c,ie.POINTER_MOVE,()=>c.remove())),r.add(q(c,ie.MOUSE_DOWN,()=>c.remove())),r.add(q(c,"touchstart",()=>c.remove())),r.add(q(c,"touchmove",()=>c.remove()));
grep -E -o -q ',r\.add\(\w+\(\w+,\w+\.MOUSE_DOWN,\(\)=>\w+\.remove\(\)\)\),\w+\.add\(\w+\(\w+,"touchstart",\(\)=>\w+\.remove\(\)\)\),\w+\.add\(\w+\(\w+,"touchmove",\(\)=>\w+\.remove\(\)\)\);' "${js}"

sed -E -i "s^(,)(this\\.B\\(this\\.a\\.onDidLayoutChange\\(\\(\\)=>this\\.r\\.hide\\(\\)\\)\\)\\})^\1${isAndroid}||\2^g" "${js}"
# ,Pdt||this.B(this.a.onDidLayoutChange(()=>this.r.hide()))}
grep -E -o -q ',.{1,3}\|\|this\.B\(this\.a\.onDidLayoutChange\(\(\)=>this\.r\.hide\(\)\)\)\}' "${js}"

msg "Done"
