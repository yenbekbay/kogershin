#import "SnapshotHelper.js"

var target = UIATarget.localTarget();
var app = target.frontMostApp();
var window = app.mainWindow();

target.delay(3);
captureLocalizedScreenshot("0-Parcels");

app.navigationBar().rightButton().tap();
target.delay(2);
captureLocalizedScreenshot("1-AddParcel");
app.navigationBar().tapWithOptions({tapOffset:{x:0.04, y:0.28}});
target.delay(1);

window.tableViews()[0].tapWithOptions({tapOffset:{x:0.46, y:0.06}});
target.delay(1);
captureLocalizedScreenshot("2-ParcelEvents");
