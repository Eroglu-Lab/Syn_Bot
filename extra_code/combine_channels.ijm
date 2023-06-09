dir1  = getDirectory("Choose Red Directory ");
dir2  = getDirectory("Choose Green Directory ");
dir3  = getDirectory("Choose Output Directory ");
list1  = getFileList(dir1);
list2 = getFileList(dir2);
setBatchMode(true);


for (i = 0; i < list1.length; i++) {
	//print(list1[i]);
	open(dir1 + list1[i]);
	title1 = getTitle();
	open(dir2 + list2[i]);
	title2 = getTitle();

	titleArray = split(title1, ".");
	title = titleArray[0];
	print(title);

	titleArray = split(title2, ".");

	if(title != titleArray[0]){
		print("error: merging different images");
	}

	

	run("Merge Channels...", "c1=["+title1+"] c2=["+title2+"] create");
	
	
	saveAs("Tiff", dir3 + title + " (combined).tif");

	
	close("*");
}
