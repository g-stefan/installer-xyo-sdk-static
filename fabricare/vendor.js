// Created by Grigore Stefan <g_stefan@yahoo.com>
// Public domain (Unlicense) <http://unlicense.org>
// SPDX-FileCopyrightText: 2022-2024 Grigore Stefan <g_stefan@yahoo.com>
// SPDX-License-Identifier: Unlicense

messageAction("vendor");

projectList = JSON.decode(Shell.fileGetContents("source/projects.json"));
function useProject(projectName) {
	for (var projectCategory of projectList) {
		for (var project of projectCategory) {
			if (project == projectName) {
				return true;
			};
		};
	};
	return false;
};

Shell.mkdirRecursivelyIfNotExists("vendor");

var vendorSourceGit = "https://github.com/g-stefan";
if (Shell.hasEnv("VENDOR_SOURCE_GIT")) {
	vendorSourceGit = Shell.getenv("VENDOR_SOURCE_GIT");
};

var vendorSourceAuth = "";
if (Shell.hasEnv("VENDOR_SOURCE_AUTH")) {
	vendorSourceAuth = Shell.getenv("VENDOR_SOURCE_AUTH");
};

var projectSuper = "xyo-sdk";
var projectSource = projectSuper + "-" + Project.version + ".static.json";

if (!Shell.fileExists("vendor/" + projectSource)) {
	var cmd = "curl --insecure --location " + vendorSourceGit + "/" + projectSuper + "/releases/download/v" + Project.version + "/" + projectSource + " "+vendorSourceAuth+" --output vendor/" + projectSource;
	Console.writeLn(cmd);
	exitIf(Shell.system(cmd));
	if (!(Shell.getFileSize("vendor/" + projectSource) > 1024)) {
		messageError("download source");
		Script.exit(1);
	};
};

var jsonContent = Shell.fileGetContents("vendor/" + projectSource);
if (Script.isNil(jsonContent)) {
	messageError("load source");
	Script.exit(1);
};

var json = JSON.decode(jsonContent);

if (Script.isNil(json)) {
	messageError("decode json");
	Script.exit(1);
};

var fileList = [];

var SDKPlatform = "win64-msvc-2022.static";
for (var project in json) {
	if (!useProject(project)) {
		continue;
	};

	var release = "";
	for (var releaseInfo of json[project].release) {
		if (releaseInfo.indexOf(SDKPlatform + "-dev.7z") >= 0) {
			release = releaseInfo;
		};
	};
	if (release.length == 0) {
		for (var releaseInfo of json[project].release) {
			if (releaseInfo.indexOf(SDKPlatform + ".7z") >= 0) {
				release = releaseInfo;
			};
		};
	};
	if (release.length == 0) {
		messageError("no release for " + project);
		Script.exit(1);
	};
	fileList[fileList.length] = release;
	if (!Shell.fileExists("vendor/" + release)) {
		var cmd = "curl --insecure --location " + vendorSourceGit + "/" + project + "/releases/download/v" + json[project].version + "/" + release + " "+vendorSourceAuth+" --output vendor/" + release;
		Console.writeLn(cmd);
		exitIf(Shell.system(cmd));
		if (!(Shell.getFileSize("vendor/" + release) > 1024)) {
			Shell.remove("vendor/" + release);
			messageError("download release");
			Script.exit(1);
		};
	};
};
