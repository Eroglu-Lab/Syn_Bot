dir1 = getDir("choose source directory");

list1 = getFileList(dir1);

setBatchMode(true);

for (i = 0; i < list1.length; i++) {

	open(dir1 + File.separator + list1[i]);
	title = getTitle();
	
	saveAs("tiff", dir1 + File.separator + "WT_" + title);
	
	close("*");

}
