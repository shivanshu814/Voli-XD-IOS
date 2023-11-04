//
//  DebugData.swift
//  PineApple
//
//  Created by Tao Man Kit on 14/10/2019.
//  Copyright © 2019 Quadrant. All rights reserved.
//

import Foundation
import CoreLocation


let profileImage1 = "profile/robin.jpg"
let profileImage2 = "profile/elkt.jpg"
let profileImage3 = "profile/boogie.jpg"
let profileImage4 = "profile/billzhao.jpg"
let profileImage5 = "profile/imstillhungry.jpg"

let attachmentImage1 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_1.jpeg"
let attachmentImage2 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_2.jpeg"
let attachmentImage3 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_3.jpeg"
let attachmentImage4 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_4.jpeg"
let attachmentImage5 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_5.jpeg"
let attachmentImage6 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_6.jpeg"
let attachmentImage7 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_7.jpeg"
let attachmentImage8 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_8.jpeg"
let attachmentImage9 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_9.jpeg"
let attachmentImage10 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_10.jpeg"
let attachmentImage11 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_11.jpeg"
let attachmentImage12 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/1_12.jpeg"

let attachmentImage2_1 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/2_1.jpeg"
let attachmentImage2_2 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/2_2.jpeg"
let attachmentImage2_3 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/2_3.jpeg"
let attachmentImage2_4 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/2_4.jpeg"
let attachmentImage2_5 = "YnkWRN6Et1VmX2b59JvchFe1hXG2/2_5.jpeg"

let attachmentImage3_1 = "1/3_1.jpg"
let attachmentImage3_2 = "1/3_2.jpg"
let attachmentImage3_3 = "1/3_3.jpg"
let attachmentImage3_4 = "1/3_4.jpg"
let attachmentImage3_5 = "1/4_1.jpg"
let attachmentImage3_6 = "1/4_2.jpg"
let attachmentImage3_7 = "1/4_3.jpg"
let attachmentImage3_8 = "1/4_4.jpg"
let attachmentImage3_9 = "1/4_5.jpg"

let attachmentImage4_1 = "2/1.jpg"
let attachmentImage4_2 = "2/2.jpg"
let attachmentImage4_3 = "2/3.jpg"
let attachmentImage4_4 = "2/4.jpg"
let attachmentImage4_5 = "2/5.jpg"
let attachmentImage4_6 = "2/6.jpg"
let attachmentImage4_7 = "2/7.jpg"
let attachmentImage4_8 = "2/8.jpg"
let attachmentImage4_9 = "2/9.jpg"
let attachmentImage4_10 = "2/10.jpg"

let attachmentImage5_1 = "3/1.jpg"
let attachmentImage5_2 = "3/2.jpg"
let attachmentImage5_3 = "3/3.jpg"
let attachmentImage5_4 = "3/4.jpg"
let attachmentImage5_5 = "3/5.jpg"
let attachmentImage5_6 = "3/6.jpg"
let attachmentImage5_7 = "3/7.jpg"
let attachmentImage5_8 = "3/8.jpg"
let attachmentImage5_9 = "3/9.jpg"
let attachmentImage5_10 = "3/10.jpg"

let attachmentImage6_1 = "4/1.jpg"
let attachmentImage6_2 = "4/2.jpg"
let attachmentImage6_3 = "4/3.jpg"
let attachmentImage6_4 = "4/4.jpg"
let attachmentImage6_5 = "4/5.jpg"
let attachmentImage6_6 = "4/6.jpg"
let attachmentImage6_7 = "4/7.jpg"
let attachmentImage6_8 = "4/8.jpg"
let attachmentImage6_9 = "4/9.jpg"
let attachmentImage6_10 = "4/10.jpg"

let debugSetting = [Setting(title: "Private profile", isEnabled: false),
                    Setting(title: "Request to follow", isEnabled: false),
                    Setting(title: "Itinerary visibility", isEnabled: false),
                    Setting(title: "Private messaging", isEnabled: false),
                    Setting(title: "Message from followers", isEnabled: false),
                    Setting(title: "New follower", isEnabled: false)
]



let debugTags = [TagCellViewModel(tag: "Street art"),
                 TagCellViewModel(tag: "Photography"),
                 TagCellViewModel(tag: "barista cafe"),
                 TagCellViewModel(tag: "Shopping"),
                 TagCellViewModel(tag: "Concert"),
                 TagCellViewModel(tag: "Travel"),
                 TagCellViewModel(tag: "Coffee"),
                 TagCellViewModel(tag: "Hip hop"),
                 TagCellViewModel(tag: "Tattpp"),
                 TagCellViewModel(tag: "Nightlife"),
                 TagCellViewModel(tag: "Dancing")]

class DebugData {
    
    static let shared = DebugData()
    
    
    
    var debugUserA = User(id: "xxxx", displayName: "Billzhao", firstName: "Steven", lastName: "Tao",  profileImageUrl: profileImage1, thumbnail: profileImage1, location: "Sydney", email: "xxx@xxx.com", phone: "90973837", tags: ["Tattoo", "cafe"], itineraryCount: 12, followerCount: 33, followingCount: 222, followingUsers: [], about: "We call our group Urban Caterpillar, a name derived from our multi-stop approach to city exploration.", fbId: "10156994539743593", setting: debugSetting, loginType: "email")

    var debugUserB = User(id: "xqqwqxxx", displayName: "Boogie", firstName: "Steven", lastName: "Tao", profileImageUrl: profileImage2, thumbnail: profileImage2, location: "Hong Kong", email: "xxx@xxx.com", phone: "90973837", tags: ["Nightlife", "Dinner"], itineraryCount: 17, followerCount: 33, followingCount: 222, followingUsers: [], about: "We call our group Urban Caterpillar, a name derived from our multi-stop approach to city exploration.", fbId: "10157663880083593", setting: debugSetting, loginType: "email")

    var debugUserC = User(id: "xxwwwwxx", displayName: "Elkt", firstName: "Steven", lastName: "Tao", profileImageUrl: profileImage3,thumbnail: profileImage3,location: "Hong Kong", email: "xxx@xxx.com", phone: "90973837", tags: ["Concert", "Hip pop"], itineraryCount: 19, followerCount: 33, followingCount: 222, followingUsers: [], about: "We call our group Urban Caterpillar, a name derived from our multi-stop approach to city exploration.", fbId: "10157663880083593", setting: debugSetting, loginType: "email")

    var debugUserD = User(id: "xxwwwwxx", displayName: "Imstillhungry", firstName: "Steven", lastName: "Tao", profileImageUrl: profileImage4, thumbnail: profileImage4, location: "Hong Kong", email: "xxx@xxx.com", phone: "90973837", tags: ["Concert", "Hip pop"], itineraryCount: 19, followerCount: 33, followingCount: 222, followingUsers: [], about: "We call our group Urban Caterpillar, a name derived from our multi-stop approach to city exploration.", fbId: "10157663880083593", setting: debugSetting, loginType: "email")

    var debugUserE = User(id: "xxwwwwxx", displayName: "Robin", firstName: "Steven", lastName: "Tao", profileImageUrl: profileImage5, thumbnail: profileImage5, location: "Hong Kong", email: "xxx@xxx.com", phone: "90973837", tags: ["Concert", "Hip pop"], itineraryCount: 19, followerCount: 33, followingCount: 222, followingUsers: [], about: "We call our group Urban Caterpillar, a name derived from our multi-stop approach to city exploration.", fbId: "10157663880083593", setting: debugSetting, loginType: "email")

    
    let debugAttachment = Attachment(path: attachmentImage1, identifier: attachmentImage1, location: CLLocationCoordinate2D(latitude: -45.032797, longitude: 168.660632), date: Styles.dateFormatter_HHmma.date(from: "09:00am"))

    let debugAttachment1 = Attachment(path: attachmentImage2, identifier: attachmentImage2, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment2 = Attachment(path: attachmentImage3, identifier: attachmentImage3, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment3 = Attachment(path: attachmentImage4, identifier: attachmentImage4, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment4 = Attachment(path: attachmentImage5, identifier: attachmentImage5, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment5 = Attachment(path: attachmentImage6, identifier: attachmentImage6, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment6 = Attachment(path: attachmentImage7, identifier: attachmentImage7, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment7 = Attachment(path: attachmentImage8, identifier: attachmentImage8, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment8 = Attachment(path: attachmentImage9, identifier: attachmentImage9, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment9 = Attachment(path: attachmentImage10, identifier: attachmentImage10, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment10 = Attachment(path: attachmentImage11, identifier: attachmentImage11, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment11 = Attachment(path: attachmentImage12, identifier: attachmentImage12, location: CLLocationCoordinate2D(latitude: -33.915846, longitude: 151.044273), date: Date())

    let debugAttachment2_1 = Attachment(path: attachmentImage2_1, identifier: attachmentImage2_1, location: CLLocationCoordinate2D(latitude: 22.293057, longitude: 114.174051), date: Styles.dateFormatter_HHmma.date(from: "06:00pm"))

    let debugAttachment2_2 = Attachment(path: attachmentImage2_2, identifier: attachmentImage2_2, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment2_3 = Attachment(path: attachmentImage2_3, identifier: attachmentImage2_3, location: CLLocationCoordinate2D(latitude: 22.280145, longitude: 114.184847), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment2_4 = Attachment(path: attachmentImage2_4, identifier: attachmentImage2_4, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment2_5 = Attachment(path: attachmentImage2_5, identifier: attachmentImage2_5, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))


    let debugAttachment3_1 = Attachment(path: attachmentImage3_1, identifier: attachmentImage3_1, location: CLLocationCoordinate2D(latitude: 22.293057, longitude: 114.174051), date: Styles.dateFormatter_HHmma.date(from: "06:00pm"))
    let debugAttachment3_2 = Attachment(path: attachmentImage3_2, identifier: attachmentImage3_2, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_3 = Attachment(path: attachmentImage3_3, identifier: attachmentImage3_3, location: CLLocationCoordinate2D(latitude: 22.280145, longitude: 114.184847), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_4 = Attachment(path: attachmentImage3_4, identifier: attachmentImage3_4, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_5 = Attachment(path: attachmentImage3_5, identifier: attachmentImage3_5, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_6 = Attachment(path: attachmentImage3_6, identifier: attachmentImage3_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_7 = Attachment(path: attachmentImage3_7, identifier: attachmentImage3_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_8 = Attachment(path: attachmentImage3_8, identifier: attachmentImage3_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment3_9 = Attachment(path: attachmentImage3_9, identifier: attachmentImage3_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment4_1 = Attachment(path: attachmentImage4_1, identifier: attachmentImage4_1, location: CLLocationCoordinate2D(latitude: 22.293057, longitude: 114.174051), date: Styles.dateFormatter_HHmma.date(from: "06:00pm"))
    let debugAttachment4_2 = Attachment(path: attachmentImage4_2, identifier: attachmentImage4_2, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_3 = Attachment(path: attachmentImage4_3, identifier: attachmentImage4_3, location: CLLocationCoordinate2D(latitude: 22.280145, longitude: 114.184847), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_4 = Attachment(path: attachmentImage4_4, identifier: attachmentImage4_4, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_5 = Attachment(path: attachmentImage4_5, identifier: attachmentImage4_5, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_6 = Attachment(path: attachmentImage4_6, identifier: attachmentImage4_6, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_7 = Attachment(path: attachmentImage4_7, identifier: attachmentImage4_7, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_8 = Attachment(path: attachmentImage4_8, identifier: attachmentImage4_8, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_9 = Attachment(path: attachmentImage4_9, identifier: attachmentImage4_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment4_10 = Attachment(path: attachmentImage4_10, identifier: attachmentImage4_10, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment5_1 = Attachment(path: attachmentImage5_1, identifier: attachmentImage5_1, location: CLLocationCoordinate2D(latitude: 22.293057, longitude: 114.174051), date: Styles.dateFormatter_HHmma.date(from: "06:00pm"))
    let debugAttachment5_2 = Attachment(path: attachmentImage5_2, identifier: attachmentImage5_2, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_3 = Attachment(path: attachmentImage5_3, identifier: attachmentImage5_3, location: CLLocationCoordinate2D(latitude: 22.280145, longitude: 114.184847), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_4 = Attachment(path: attachmentImage5_4, identifier: attachmentImage5_4, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_5 = Attachment(path: attachmentImage5_5, identifier: attachmentImage5_5, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_6 = Attachment(path: attachmentImage5_6, identifier: attachmentImage5_6, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_7 = Attachment(path: attachmentImage5_7, identifier: attachmentImage5_7, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_8 = Attachment(path: attachmentImage5_8, identifier: attachmentImage5_8, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_9 = Attachment(path: attachmentImage5_9, identifier: attachmentImage5_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment5_10 = Attachment(path: attachmentImage5_10, identifier: attachmentImage5_10, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))

    let debugAttachment6_1 = Attachment(path: attachmentImage6_1, identifier: attachmentImage6_1, location: CLLocationCoordinate2D(latitude: 22.293057, longitude: 114.174051), date: Styles.dateFormatter_HHmma.date(from: "06:00pm"))
    let debugAttachment6_2 = Attachment(path: attachmentImage6_2, identifier: attachmentImage6_2, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_3 = Attachment(path: attachmentImage6_3, identifier: attachmentImage6_3, location: CLLocationCoordinate2D(latitude: 22.280145, longitude: 114.184847), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_4 = Attachment(path: attachmentImage6_4, identifier: attachmentImage6_4, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_5 = Attachment(path: attachmentImage6_5, identifier: attachmentImage6_5, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_6 = Attachment(path: attachmentImage6_6, identifier: attachmentImage6_6, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_7 = Attachment(path: attachmentImage6_7, identifier: attachmentImage6_7, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_8 = Attachment(path: attachmentImage6_8, identifier: attachmentImage6_8, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_9 = Attachment(path: attachmentImage6_9, identifier: attachmentImage6_9, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    let debugAttachment6_10 = Attachment(path: attachmentImage6_10, identifier: attachmentImage6_10, location: CLLocationCoordinate2D(latitude: -45.076644, longitude: 168.741282), date: Styles.dateFormatter_HHmma.date(from: "02:00pm"))
    
    var debugActivity = Activity(itineraryId: "111", attachments: [], tag: [], description: "Anywhere here are nice, the population is around 20,000 local residents, so most of the people you see in this city are tourists. 1 local : 30 tourists.", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00am")!, location: "Queenstown City Centre, NZ", latitude: -45.032797, longitude: 168.660632,  subLocality: "Queenstown, New Zealand")

    var debugActivity1 = Activity(itineraryId: "222", attachments: [], tag: [], description: "This place is photogenic, relaxing and refreshing", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "02:00pm")!, location: "Jack's Point Golf Course & Clubhouse", latitude: -45.076660, longitude: 168.741282, subLocality: "Queenstown, New Zealand")

    var debugActivity2 = Activity(itineraryId: "333", attachments: [], tag: ["ferry in hk,", "渡海小輪"], description: "Catch a ferry from harbour in Kowloon ", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "06:00pm")!, location: "Tsim Sha Tsui East Harbour", latitude: 22.293057, longitude: 114.174051, subLocality: "Hong Kong")

    var debugActivity3 = Activity(itineraryId: "444", attachments: [], tag: ["Cyber punk", "beer pong,", "hk bars"], description: "Beer pong x Cyber Punk at Causeway Bay", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00pm")!, location: "Flat 61 bar, 13/F Ying Hong Mansion, 2-6 Yee Woo St, Causeway Bay, Hong Kong", latitude: 22.280145, longitude: 114.184847, subLocality: "Hong Kong")

    // 1
    var debugActivity4 = Activity(itineraryId: "5555", attachments: [], tag: ["Street art"], description: "Visit us at Paddington and see our workshop", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "06:00pm")!, location: "Paddington, Sydney", latitude: 22.293057, longitude: 114.174051, subLocality: "Paddington, Sydney")

    var debugActivity5 = Activity(itineraryId: "6", attachments: [], tag: ["Local culture"], description: "Arts & Animations by me & some friends", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00pm")!, location: "National Gallery Museum, Sydney", latitude: 22.280145, longitude: 114.184847, subLocality: "National Gallery Museum, Sydney")

    // 2
    var debugActivity6 = Activity(itineraryId: "7", attachments: [], tag: ["NY Streets"], description: "There is no ferry service to Governors Island from Brooklyn on weekdays", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "06:00pm")!, location: "Jefferson stop, Brooklyn, NY", latitude: 22.293057, longitude: 114.174051, subLocality: "Jefferson stop, Brooklyn, NY")

    var debugActivity7 = Activity(itineraryId: "8", attachments: [], tag: ["Culture"], description: "Catch a Ferry when you arrive Manhattan", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00pm")!, location: "Battery Maritime Building, Manhattan", latitude: 22.280145, longitude: 114.184847, subLocality: "Battery Maritime Building, Manhattan")

    // 3
    var debugActivity8 = Activity(itineraryId: "9", attachments: [], tag: ["Street art"], description: "Breakfast at farmer's market", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "06:00pm")!, location: "Bangkok, Thailand", latitude: 22.293057, longitude: 114.174051, subLocality: "Bangkok, Thailand")

    var debugActivity9 = Activity(itineraryId: "10", attachments: [], tag: ["Local culture"], description: "Breakfast at farmer's market", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00pm")!, location: "Chippendale, Sydney", latitude: 22.280145, longitude: 114.184847, subLocality: "Chippendale, Sydney")

    // 4
    var debugActivity10 = Activity(itineraryId: "11", attachments: [], tag: ["Hip Hop"], description: "What you do when the snow doesn't stop", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "06:00pm")!, location: "Broadway Dance Club, 34 St", latitude: 22.293057, longitude: 114.174051, subLocality: "Broadway Dance Club, 34 St")

    var debugActivity11 = Activity(itineraryId: "12", attachments: [], tag: ["BDC", "Snowy NYC"], description: "Anyone can walk in and have a dance class", timeSpend: 60*60, startTime: Styles.dateFormatter_HHmma.date(from: "09:00pm")!, location: "Broadway Dance Club, 34 St", latitude: 22.280145, longitude: 114.184847, subLocality: "Broadway Dance Club, 34 St")
    
    
    var debugItinerary2 = ItineraryViewModel(itinerary:Itinerary(id: "222", title: "Ferry trip to a speakeasy on the Island.",description: "hangout with your new friends from your country and the locals in this fun bar, where you can immerse into the Cyber Punk outfit of HK",activities: [],user: User(),isLike: true,isSave: true, isCommented: false, likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: false, isAllowContact: false, distance: 0))

    var debugItinerary3 = ItineraryViewModel(itinerary:Itinerary(id: "333", title: "Dancing animations and arts", description: "Sneak peek at my collab piece with Raediant movement in the current nationalgallerywest exhibition, join our art workshops and meet other artists at the precinct.",activities: [],user: User(),isLike: true,isSave: true, isCommented: false, likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: false, isAllowContact: false, distance: 0))

    var debugItinerary4 = ItineraryViewModel(itinerary:Itinerary(id: "444", title: "Untapped Governors Island",description: "Explore how to capture candid photos of your subject with photographic artist Eric K.T. Lau. How he arrived at his streamlined approach shooting solely on iPhone.",activities: [],user: User(),isLike: true,isSave: true,isCommented: false,likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: false, isAllowContact: false, distance: 0))

    var debugItinerary5 = ItineraryViewModel(itinerary:Itinerary(id: "555", title: "Lives of people in Bangkok",description: "Early adventurers like Lewis & Clark exploring the Rocky Mountains are legendary.  about everyone will find something to enjoy on a Rocky Mountain holiday. ",activities: [],user: User() ,isLike: true,isSave: true,isCommented: false,likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: false, isAllowContact: false, distance: 0))

    var debugItinerary6 = ItineraryViewModel(itinerary:Itinerary(id: "666", title: "What you do when the snow won’t stop",description: "New York’s multicultural Hip Hop culture, the itinerary is my daily life, where my friends and I hangout, you will see places that you can walk-in and have a dance class too. ",activities: [],user: User(),isLike: true,isSave: true,isCommented: false,likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: false, isAllowContact: false, distance: 0))

    var debugItinerary_P = ItineraryViewModel(itinerary:Itinerary(id: "6661", title: "Vintage hunter & finder keepers market",description: "Snapshot of Sydney's coolest inner city haunts - ideal for those who wish to see more than just the Opera House and Harbour Bridge.",activities: [],user: User(),isLike: true,isSave: true,isCommented: false,likeCount: 123,commentCount: 475,savedCount: 234, createDate: Date(), isPrivate: true, isAllowContact: false, distance: 0))
    
    var suggestedKeywords = ["tattoo", "tattoo artist", "tattoo artist in Paris", "tattoo artist specialised in portrait", "tattoo tattoo artist"]
    
    var debugItineraries: [Itinerary]!
    var debugItineraries_sameUser: [ItineraryDetailViewModel]!
    var debugItineraries_similar: [ItineraryDetailViewModel]!
    var debugItineraries_my: [ItineraryDetailViewModel]!
    
//    var debugCollections: [SavedCollection]!
    var debugUsers: [User]!
    
    func setup() {
        debugUserA.followingUsers = [debugUserB, debugUserC]
        debugUserB.followingUsers = [debugUserA, debugUserC]
        debugUserC.followingUsers = [debugUserD, debugUserE]
        debugUserD.followingUsers = [debugUserA, debugUserE]
        debugUserE.followingUsers = [debugUserC, debugUserB]
        
        debugActivity.attachments = [debugAttachment, debugAttachment1, debugAttachment2, debugAttachment3, debugAttachment4, debugAttachment5]
        
        debugActivity1.attachments = [debugAttachment6, debugAttachment7, debugAttachment8, debugAttachment9, debugAttachment10, debugAttachment11]
        
        debugActivity2.attachments = [debugAttachment2_1, debugAttachment2_2]
        
        debugActivity3.attachments = [debugAttachment2_3, debugAttachment2_4, debugAttachment2_5]
        
        debugActivity4.attachments = [debugAttachment3_1, debugAttachment3_2, debugAttachment3_3, debugAttachment3_4]
        
        debugActivity5.attachments = [debugAttachment3_5, debugAttachment3_6, debugAttachment3_7, debugAttachment3_8, debugAttachment3_9]
        
        debugActivity6.attachments = [debugAttachment4_1, debugAttachment4_2, debugAttachment4_3, debugAttachment4_4]
        
        debugActivity7.attachments = [debugAttachment4_5, debugAttachment4_6, debugAttachment4_7, debugAttachment4_8, debugAttachment4_9, debugAttachment4_10]
        
        debugActivity8.attachments = [debugAttachment5_1, debugAttachment5_2, debugAttachment5_3, debugAttachment5_4]
        
        debugActivity9.attachments = [debugAttachment5_5, debugAttachment5_6, debugAttachment5_7, debugAttachment5_8, debugAttachment5_9, debugAttachment5_10]
        
        debugActivity10.attachments = [debugAttachment6_1, debugAttachment6_2, debugAttachment6_3, debugAttachment6_4]
        
        debugActivity11.attachments = [debugAttachment4_5, debugAttachment4_6, debugAttachment4_7, debugAttachment6_8, debugAttachment6_9, debugAttachment6_10]
            
        var model = debugItinerary2.model
        model.activities = [debugActivity2, debugActivity3]
        model.user = debugUserE
        debugItinerary2.setup(with: model)
        
        
        model = debugItinerary3.model
        model.activities = [debugActivity4, debugActivity5]
        model.user = debugUserA
        debugItinerary3.setup(with: model)
        
        model = debugItinerary4.model
        model.activities = [debugActivity6, debugActivity7]
        model.user = debugUserB
        debugItinerary4.setup(with: model)
        
        model = debugItinerary5.model
        model.activities = [debugActivity8, debugActivity9]
        model.user = debugUserC
        debugItinerary5.setup(with: model)
        
        model = debugItinerary6.model
        model.activities = [debugActivity10, debugActivity11]
        model.user = debugUserD
        debugItinerary6.setup(with: model)
        
        model = debugItinerary_P.model
        model.activities = [debugActivity, debugActivity1]
        model.user = debugUserE
        debugItinerary_P.setup(with: model)
        
        debugItineraries = [            
            debugItinerary3.model,
            debugItinerary4.model,
            debugItinerary5.model,
            debugItinerary6.model
        ]
        
        debugItineraries_sameUser = [
            ItineraryDetailViewModel(itinerary: debugItinerary4),
            ItineraryDetailViewModel(itinerary: debugItinerary5),
            ItineraryDetailViewModel(itinerary: debugItinerary3)
        ]

        debugItineraries_similar = [
            ItineraryDetailViewModel(itinerary: debugItinerary4),
            ItineraryDetailViewModel(itinerary: debugItinerary5),
            ItineraryDetailViewModel(itinerary: debugItinerary6)
        ]

        debugItineraries_my = [
            ItineraryDetailViewModel(itinerary: debugItinerary_P),
            ItineraryDetailViewModel(itinerary: debugItinerary3),
            ItineraryDetailViewModel(itinerary: debugItinerary4),
            ItineraryDetailViewModel(itinerary: debugItinerary5),
            ItineraryDetailViewModel(itinerary: debugItinerary6)
            
        ]
         
//        debugCollections = [SavedCollection(id: "1", name: "Hong Kong", itineraries: [
//            ItineraryDetailViewModel(itinerary: debugItinerary5), ItineraryDetailViewModel(itinerary: debugItinerary3), ItineraryDetailViewModel(itinerary: debugItinerary4)]),
//                            SavedCollection(id: "1", name: "Melbourne", itineraries: [ItineraryDetailViewModel(itinerary: debugItinerary5),  ItineraryDetailViewModel(itinerary: debugItinerary3), ItineraryDetailViewModel(itinerary: debugItinerary4)])]
        
        debugUsers = [debugUserA, debugUserB, debugUserC]
    }
    

    
}
