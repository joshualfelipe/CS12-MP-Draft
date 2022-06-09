# CS12-MP-Draft

- [x] Potential Improvements
	- [x] Refactor `update-egg-ongoing()` into separate functions
	- [x] Combine `update-platforms-y()` and `egg-transition()` into `transition-stage()`
	- [-] ~Egg keeps lightly moving on platform (Pips' suggestion leave as is since it's not that noticeable)~
		- This is due to the delay between the egg's dx and the current platform's dx updating.
		- Could modify `check-platform-side-collision()`
	- [-] ~~Refactor "Current platform" tracking logic~~
		- Seems convoluted
	- [x] Documentation in `update-platform()`
		- Specifically the if statements
	- [x] Modify `INITIAL-STATE` Logic to separate platform generation and egg copying

- Pips' new modification to platforms
	- Removed get-new-platforms and immediately used it in `update-platforms-y()`
	- Made `make-pair-platforms()` able to add and remove existing platforms. 
	- Changed list `other-platforms` pre-values to 0 and -125. 
	- Changed new-top.y to (new-top.y - 1) in `update-platforms-y()` to ensure that all platforms align after transitioning.
	- Added `HIDDEN-PLATFORM-Y-COORDINATE` to ensure dynamic change in hidden pre-platform-1 & 2 when height of platform is changed.
	- Added comments on various parts of the code.