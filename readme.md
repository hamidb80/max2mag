# Max To Mag :: max2mag

## Resources
[_how to download them all?_](https://www.tupp.me/2014/06/how-to-crawl-website-with-linux-wget.html)

```bash
wget --no-parent -k -U mozilla -e robots=off -r URL
```

1. [`.mag` sample files](http://www.ece.sunysb.edu/~psun/ese355/scmoscell/index.htm) 
2. [Magic tutorial](http://opencircuitdesign.com/magic/tutorials/)

## File Syntax Info
### .mag
#### commands
```bash
grep -r -h -o --include="*.mag" '^\w\+' | uniq  
```
```
magic
rect
rlabel
tech
timestamp
```

### .max
```tcl
DEF #fet!-fingers!2!-width!2.0!-_version!1291998914 "fet (S)" "2 X 2.0/0.18"
```

replace `!` with space:
```tcl
DEF #fet -fingers 2 -width 2.0 -_version 1291998914 "fet (S)" "2 X 2.0/0.18"
```

- read about `gcell` in `max_manual/apndxc.html`