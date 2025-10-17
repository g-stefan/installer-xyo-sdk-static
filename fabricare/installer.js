// Created by Grigore Stefan <g_stefan@yahoo.com>
// Public domain (Unlicense) <http://unlicense.org>
// SPDX-FileCopyrightText: 2022-2024 Grigore Stefan <g_stefan@yahoo.com>
// SPDX-License-Identifier: Unlicense

messageAction("installer");

Shell.mkdirRecursivelyIfNotExists("release");

Shell.setenv("PRODUCT_NAME", "installer-xyo-sdk-static");
Shell.setenv("PRODUCT_VERSION", Project.version);
Shell.setenv("PRODUCT_BASE", "xyo-sdk");
Shell.setenv("PRODUCT_PLATFORM", Platform.name);

exitIf(Shell.system("makensis.exe /NOCD \"source\\xyo-sdk-static-installer.nsi\""));
exitIf(Shell.system("grigore-stefan.sign \"XYO SDK\" \"release\\xyo-sdk-static-" + Project.version + "-installer.exe\""));

var fileName = "xyo-sdk-static-" + Project.version + "-installer.exe";
var jsonName = "xyo-sdk-static-" + Project.version + "-installer.json";

var json = {};
json[fileName] = SHA512.fileHash("release/" + fileName);
Shell.filePutContents("release/" + jsonName, JSON.encodeWithIndentation(json));
