{
   Started On:		   10.10.2012.
}

{$MODE OBJFPC}{$H+}
UNIT appuAndroidSysInfo;

INTERFACE

	USES StringUtils, uPropertySection, appuSysInfoBase, appuLinuxSysInfo;

CONST
   APP_ANDROID_BUILD_PROP_SECTION		      = 'android_build';

   APP_ANDROID_BUILD_PROP_MANUFACTURER 		= 0001;
   APP_ANDROID_BUILD_PROP_PRODUCT		      = 0002;
   APP_ANDROID_BUILD_PROP_MODEL			      = 0003;

   APP_ANDROID_BUILD_PROP_VERSION_CODENAME	= 0004;
   APP_ANDROID_BUILD_PROP_VERSION_SDK_INT	   = 0005;
   APP_ANDROID_BUILD_PROP_VERSION_RELEASE	   = 0006;

VAR
   android_build: record
      MANUFACTURER,
      PRODUCT,
      MODEL: string;

      VERSION: record
         CODENAME: string;
         SDK_INT: longint;
         RELEASE: string;
      end;
   end;

   appAndroidBuildPropertySection: TPropertySection;

IMPLEMENTATION


procedure getInformation();
begin
   appLinuxSysInfoGetInformation();

   appSI.systemName := android_build.VERSION.CODENAME + ' ('+
      sf(android_build.VERSION.SDK_INT)+','+
      android_build.VERSION.RELEASE+')';

   appSI.systemDeviceName := android_build.manufacturer + ' ' +
      android_build.PRODUCT + '('+android_build.MODEL+')';
end;

procedure setString(code: longint; const prop: string);
begin
   case code of
      APP_ANDROID_BUILD_PROP_MANUFACTURER:
         android_build.MANUFACTURER := prop;
      APP_ANDROID_BUILD_PROP_PRODUCT:
         android_build.PRODUCT := prop;
      APP_ANDROID_BUILD_PROP_MODEL:
         android_build.MODEL := prop;

      APP_ANDROID_BUILD_PROP_VERSION_CODENAME:
         android_build.VERSION.CODENAME := prop;
      APP_ANDROID_BUILD_PROP_VERSION_RELEASE:
         android_build.VERSION.RELEASE := prop;
   end;
end;

procedure setInt(code: longint; prop: longint);
begin
   case code of
      APP_ANDROID_BUILD_PROP_VERSION_SDK_INT:
         android_build.VERSION.SDK_INT := prop;
   end;
end;

INITIALIZATION
   appAndroidBuildPropertySection            := propertySections.dummy;
   appAndroidBuildPropertySection.Name       := APP_ANDROID_BUILD_PROP_SECTION;
   appAndroidBuildPropertySection.setString  := @setString;
   appAndroidbuildPropertySection.setInt     := @setInt;

   propertySections.Register(appAndroidbuildPropertySection);

   appSI.getInformation := @getInformation;
END.

