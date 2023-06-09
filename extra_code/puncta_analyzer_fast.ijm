dir1 = getDir("choose source directory");
list1 = getFileList(dir1);
roiR = 301;

for (i = 0; i < list1.length; i++) {
	if (i == 0){
		open(dir1 + File.separator + list1[i]);
		setTool("point");
		waitForUser("Select center of ROI and click OK");
		Roi.getBounds(x, y, width, height);
		makeOval(x - roiR, y - roiR, roiR*2, roiR*2);
		run("Puncta Analyzer", "condition=[] red green subtract set save rolling=50");
		close();
		selectWindow("Results");
		run("Close");
		selectWindow("ROI Manager");
		run("Close");
		selectWindow("Summary");
		run("Close");
	}
	else {
		open(dir1 + File.separator + list1[i]);
		setTool("point");
		waitForUser("Select center of ROI and click OK");
		Roi.getBounds(x, y, width, height);
		makeOval(x - roiR, y - roiR, roiR*2, roiR*2);
		run("Puncta Analyzer", "condition=[] red green subtract save rolling=50");
		close();
		selectWindow("Results");
		run("Close");
		selectWindow("ROI Manager");
		run("Close");
		selectWindow("Summary");
		run("Close");
	}
}
