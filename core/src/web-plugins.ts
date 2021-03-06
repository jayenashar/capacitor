import { mergeWebPlugin } from './plugins';

import { App } from './web/app';
import { Browser } from './web/browser';
import { Camera } from './web/camera';
import { Device } from './web/device';
import { Filesystem } from './web/filesystem';
import { Geolocation } from './web/geolocation';
import { LocalNotifications } from './web/local-notifications';
import { Modals } from './web/modals';
import { Share } from './web/share';
import { SplashScreen } from './web/splash-screen';
import { Toast } from './web/toast';

export * from './web/app';
export * from './web/browser';
export * from './web/camera';
export * from './web/device';
export * from './web/filesystem';
export * from './web/geolocation';
export * from './web/local-notifications';
export * from './web/modals';
export * from './web/share';
export * from './web/splash-screen';
export * from './web/toast';

mergeWebPlugin(App);
mergeWebPlugin(Browser);
mergeWebPlugin(Camera);
mergeWebPlugin(Device);
mergeWebPlugin(Filesystem);
mergeWebPlugin(Geolocation);
mergeWebPlugin(LocalNotifications);
mergeWebPlugin(Modals);
mergeWebPlugin(Share);
mergeWebPlugin(SplashScreen);
mergeWebPlugin(Toast);
