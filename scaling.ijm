/////////////////////// begin macro
requires( "1.51t" );
run( "8-bit" );
b = 10;
setScaleFromBar( b );
exit();
/////////////////////// end macro
/////////////////////// begin functions
function diff( aa ) {
	for ( i = 1; i < aa.length; i++ ) {
		aa[i-1] = aa[i] - aa[i-1];
	}
	aa[aa.length-1] = 0;
}
function getBeginEnd( aaa ) {
	mi = Array.findMinima( aaa, 0 );
	mx = Array.findMaxima( aaa, 0 );
	if ( mx[0] < mi[0] ) aaa[1] = mx[1]; else aaa[1] = mx[0];
	if ( mi[0] > aaa[1] ) aaa[0] = mi[1]; else aaa[0] = mi[0];
}
function setScaleFromBar( bb ) {
	run( "Set Scale...", "distance=0 known=0 pixel=1 unit=pixel" );
	ww = getWidth();
	makeRectangle( 0, bb, ww, getHeight() - 2 * bb );
	setKeyDown( "alt" );
	a = getProfile();
	setKeyDown( "none" );
	min = Array.findMinima( a, 0 );
	if ( min[0] > min[1] ) yy = min[1]; else yy = min[0];
	pel = abs( min[1] - min[0] );
	a = Array.slice( a, yy + pel );
	diff( a );
	getBeginEnd( a );
	makeRectangle( 0, yy + bb + pel + a[0], ww, abs( a[0] - a[1] ) );
	a = getProfile();
	run( "Select None" );
	diff( a );
	getBeginEnd( a );
	pel = abs( a[0] - a[1] );
 	run( "Set Scale...", "distance=" + pel + " known=100 unit=um" );
}
/////////////////////// end functions