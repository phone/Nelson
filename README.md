## Nelson

<img src="https://dl.dropboxusercontent.com/u/22430202/pic/Nelson.jpg" alt="typical derby" title="Typical Derby" align="left" height=492 width=345/>

Nelson is a graphical filesystem navigation tool with fuzzy search. I usually run it from p9p acme when I need to navigate large codebases with lots of directories.

### Use

* search: any character you type adds to the fuzzy search and narrows the directory listing appropriately.
* `[tab]`: select the next item in the list. If you're at the last item, it will cycle you back to the beginning.
* `[shift-tab]`: backtab selects the previous item in the list. If you're at the first item, it cycles you to the last item.
* `[backspace]`: delete a chacter from your search term. If your search term is empty, this moves you up one directory level.
* `[enter]`: if there are search results, plumb selected result. If there are no results and query ends with `/`, create directory and descend into it. If there are no results, create file named by query.
* `[esc]`: quit.

### Installing

Running the `INSTALL` script will build the `Nelson` sources, the `seticon` sources, make a `Nelson.app` bundle, and copy the appropriate files there. Then it copies the `Nelson.app` bundle to `/Applications` and creates a symlink at `/usr/local/bin/nelson` into `/Applications/Nelson.app/Contents/MacOS/Nelson`. If you want it to do something different, change the script.

### Bugs

* Only works on OS X.
* Heavily uses the text to make selections. In particular, filenames with two consecutive spaces will confuse the selection logic.
* The query text obeys strict stack discipline. Typing letters pushes, and backspace pops.
* The output listings are sorted by file `mtime`. Sometimes this has awkward side effects. See `TODO` for details.
* I don't really know Objective-C. This code surely sucks.

### License

Copyright © 2016 Elliot Pennington
Distributed under the Eclipse Public License either version 1.0 or (at your option) any later version.
