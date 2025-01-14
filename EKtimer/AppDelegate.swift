//
//  AppDelegate.swift
//  EKtimer
//
//  Created by Simon on 2021-11-17.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
     
        
        
        return true
    }
    func loadPreferences()
    {
        do {
            try AppData.load_preferences()
            ClockDevices.connect(to: AppData.getDevices().map({$0.host}))
            for dev in AppData.getDevices() {
                ClockDevices.settings(for_host: dev.host, values: ["Intensity": UInt8(dev.intensity) as AnyObject, "SignalTime": UInt8(dev.beep_interval) as AnyObject])
            }
        } catch {
            print("Failed to load preferences: \(error)")
        }
    }
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        loadPreferences()
      
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        self.window?.rootViewController?.dismiss(animated: false)
        print("applicationWillEnterForeground")
        loadPreferences()
        
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
       print("applicationDidBecomeActive")
      
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        do {
            try AppData.save_preferences()
        } catch {
            print("Failed to save preferences: \(error)")
        }
    }

    func application(_ application: UIApplication, shouldSaveSecureApplicationState coder: NSCoder) -> Bool {
        return true;
    }
    func application(_ application: UIApplication, shouldRestoreSecureApplicationState coder: NSCoder) -> Bool {
        return true;
        
    }
}

