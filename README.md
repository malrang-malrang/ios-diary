# 📒 일기장
> 프로젝트 기간 2022.06.13 ~ 2022.07.01  
팀원 : [malrang](https://github.com/malrang-malrang) [Tiana](https://github.com/Kim-TaeHyun-A) / 리뷰어 : [stevenkim](https://github.com/stevenkim18)

- [실행화면](#실행화면)
- [STEP 2 구현](#step-2-구현)
    + [고민했던 것들(트러블 슈팅)](#고민했던-것들트러블-슈팅)
    + [질문한것들](#질문한것들)

## 실행화면
<img src="https://i.imgur.com/qHJ6nau.gif" width="240"><img src="https://i.imgur.com/LAax27o.gif" width="240">

## STEP 2 구현

## 고민했던 것들(트러블 슈팅)
1️⃣ **UI를 구현하기위한 sample데이터 관련 로직의 위치**

CoreData에서 데이터를 가져오기전 tableView를 구현하기위해 사용된 Asset에 저장된 sample데이터를 가져오는 로직을 어디서 관리해야할지 위치를 고민하였습니다.

추후 사용될 일이 없기때문에 ViewController를 최소화하기 위해 해당 로직을 Sample 타입을 만들어 분리하였으나 Asset을 관리하는 AssetManager타입에서 해당 기능을 수행하도록 수정하였습니다.

```swift
struct Sample {
    enum Const {
        static let sample = "sample"
    }
    
    static func get() -> [DiaryDTO]? {
        guard let assetData = AssetManager.convert(fileName: Const.sample) else {
            return nil
        }
        
        guard let diaryData = DiaryDTO.parse(data: assetData) else {
            return nil
        }
        
        return diaryData
    }
}
```
Sample 타입의 get() 메서드를 제네릭을 활용하여 Decodable을 채택하는 타입으로 반환하도록 수정하였습니다.

```swift
struct AssetManager {
    enum Const {
        static let sample = "sample"
    }
    
    private static func convert(fileName: String) -> Data? {
        guard let assetFile = NSDataAsset(name: fileName) else {
            return nil
        }
        
        return assetFile.data
    }
    
    static func get<T: Decodable>() -> [T]? {
           guard let assetData = AssetManager.convert(fileName: Const.sample) else {
               return nil
           }
           
           guard let diaryData = T.parse(data: assetData) else {
               return nil
           }
           
           return diaryData
       }
}
```
제네릭을 사용 하는 메서드(get메서드)의 호출
```swift
let sampleData: [DiaryDTO] = AssetManager.get()
```
상수나 변수에 타입 어노테이션을 사용하여 반환되는 타입을 추론할수있도록 타입을 명시해주면 된다!

2️⃣ **Keyboard타입과 KeyBoard를사용하는 주체 를 주입받는 방법** 

textView에서 사용되는 키보드관련 기능들은 KeyBoard타입 만들어 구현하였다.

textView에서 사용되는 키보드를 비활성화 하기 위해 SwipeGesture를 추가하기위해서는 KeyBoard를 사용하는 주체(ViewController, textView)를 알고있어야 해당 주체에 제스쳐를 추가해줄수 있게된다.

그렇다면 KeyBoard타입은 사용하는 주체를 알고있어야 하기때문에 프로퍼티로 가지고있어야한다고 생각했고 KeyBoard타입을 OOP 적으로 설계하기 위해 해당 프로퍼티를 은닉화하여 init()으로 주입받을지, 메서드를 사용해 주입받을지 고민하였습니다.

```swift
final class Keyboard {
    enum Const {
        static let keyboardBounds = "UIKeyboardBoundsUserInfoKey"
    }
    
    private let bottomContraint: NSLayoutConstraint?
    private let textView: UITextView?
    
    init(bottomContraint: NSLayoutConstraint, textView: UITextView) {
        self.textView = textView
        self.bottomContraint = bottomContraint
    }
```
KeyBoard타입을 초기화 할때 한번에 주입할수있도록 init()을 활용하였습니다.

3️⃣ **SceneDelegate에서 BackGround로 진입할 때 데이터를 저장하는 방법(Notification vs 델리게이트)**

백드라운드에서 진입할 때 SceneDelegate에 있는 sceneDidEnterBackground(_ scene: UIScene) 메서드가 호출됩니다.이때, 저장 메서드가 UpdateViewController 에 있어서 델리게이트를 사용해서 메서드를 호출합니다.
SceneDelegate에 프로퍼티를 선언하는 것이 단점이 될 수도 있다고 생각합니다.
반면, notification을 사용하는 경우는 UpdateViewController에 진입 후 계속 관찰해야해서 성능상으로 상대적으로 좋지 않을 것 같습니다. 또, 관찰 대상이 많을 경우 디버깅하기 어렵습니다.

```swift
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    weak var delegate: BackGroundDelegate?
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        delegate?.updateCoredata()
    }
 ...   
}

protocol BackGroundDelegate: AnyObject {
    func updateCoredata()
}

extension UpdateViewController: BackGroundDelegate {
    func updateCoredata() {
        saveData()
    }
}
```

4️⃣ **textView text에서 title 이랑 body 나누기**

UpdateViewController에서만 사용되는 extension이라서 private으로 구현했습니다.
`\n` 을 기준으로 나뉜 문자열에서 첫 문자열만 title로 설정하고 나머지는 body로 고려됩니다.
사용자가 body를 작성하지 않은 경우는 빈 문자열이 저장되도록 구현했습니다.
따라서, UpdateViewController는 별도의 프로퍼티 없이 textview의 데이터를 적절히 가져올 수 있습니다.
```swift
private extension UITextView {
    enum Const {
        static let separator: Character = "\n"
        static let defaultBody = ""
    }
    
    func extractData(date: String?) -> (
        title: String,
        body: String,
        date: Date
    )? {
        guard let date = date else {
            return nil
        }
        
        let splitedText = text.split(
            separator: Const.separator,
            maxSplits: 1
        ).map {
            String($0)
        }
        
        let body: String
        
        switch splitedText.count {
        case 1:
            body = Const.defaultBody
        case 2:
            guard let lastText = splitedText.last else {
                return nil
            }
            
            body = lastText
        default:
            return nil
        }
        
        guard let title = splitedText.first,
              let date = Formatter.getDate(from: date) else {
            return nil
        }
        
        return (title, body, date)
    }
}
```

삼항연사자와 nil 병합연산자가 상대적으로 성능이 좋지 않아서 사용을 지양하려고 했지만 가독성 측면에서 좋지 않아 둘 다 사용하기로 했습니다. 

```swift
var title: String? {
        let text = self.text.components(separatedBy: "\n")
        return text.first == "" ? nil : text.first
}
    
var body: String {
        let splitedText = self.text.split(separator: "\n", maxSplits: 1)
        let body = splitedText.map { String($0) }
        return body[safe: 1] ?? ""
}
```
위와 같이 연산프로퍼티를 통해 title과 body를 각각 전달할 수 있습니다. 이때, 접근할 때마다 text를 분리하는 단점이 존재합니다. 그렇지만, 가독성이 향상되어서 위 코드를 최종 수정에 반영했습니다.


5️⃣ **tableview 레이아웃 에러**

<img src="https://i.imgur.com/9HMBHuJ.png" width="500">

스토리보드에서 테스트해보니, 뷰 안에 레이블 넣으면 스토리보드에서 즉각적으로 높이 조절되지 않는 것을 확인했습니다. 레이블뷰가 스택뷰에 들어갈 때는 자동으로 높이 조절됩니다.

스택뷰는 intrinsic content size를 사용해서 높이를 자동으로 맞추는 것 같습니다. 반면, label을 view에 넣었을 때는 view가 스스로 높이 결정하지 못하는 것으로 보입니다.

위 에러는 테이블뷰 셀의 높이가 정해지지 않아서 발생한 문제라고 생각되어 아래 코드를 통해 해결했습니다.

<img src="https://i.imgur.com/gtIXMdN.png" width="300">

```swift
titleLabel.heightAnchor.constraint(equalTo: informationStackView.heightAnchor)
```

body가 들어가지 않는 경우 stackView에서 너비를 모호하다고 인식하는 레이아웃 에러가 생겼습니다. 이를 해결하기 위해서 아래와 같이 수정했습니다.
```swift
label.setContentHuggingPriority(
        .required,
        for: .horizontal
)
```

6️⃣ **코드 컨벤션**

[관련 링크](https://developer.apple.com/documentation/uikit/uiactivityitemsource/1620455-activityviewcontroller)
공식문서에서 매서드를 표기하는 방식과 동일하도록 컨벤션을 맞췄습니다.
매개변수가 1개 이상 들어가는 경우 줄바꿈을 했습니다.

이때, 가독성이 좋지 못하다고 느꼈습니다.
또한, 아래 공식문서의 예제 코드를 살펴보니 대부분의 경우는 개행 없이 코드 작성이 된 것을 확인했고 전반적인 코드 컨벤션을 줄바꿈을 덜 하도록 다시 수정했습니다.
[관련 링크](https://developer.apple.com/documentation/uikit/uitableviewdatasource)

7️⃣ **빌더 패턴을 적용한 alert**

다양한 형태의 alert을 구현하기 위해 빌더패턴을 사용해서 `AlertBuilder`을 구현했습니다.
설정할 값을 메서드 호출을 통해 세팅해서 간결하게 alertController를 만듭니다.
```swift
let alert = AlertBuilder()
            .setTitle("진짜요?")
            .setMessage("정말로 삭제하시겠어요?")
            .setType(.alert)
            .setAction(action)
            .build()
```

AlertBuilder() 인스턴스가 반복적으로 생성되는 것을 막기 위해 싱글톤 패턴을 적용해서 수정했습니다. 공통적으로 사용되는 인스턴스의 product 초기화가 필요해서 연산 프로퍼티를 활용해서 호출 시 새 product이 할당되도록 수정했습니다.

8️⃣ **범용적으로 사용할수있어야할까? vs 중복코드를 줄여야할까? 🫠**

기존에 사용하던 Alert관련 메서드는 구현되어있는 ViewController모두 사용하고있기때문에UIViewController를 extension하여 구현해두었습니다.

```swift
extension UIViewController {
  func showDeleteAlert(
          identifier: UUID?,
          handler: @escaping () -> Void
      ) {
          guard let identifier = identifier else {
              return
          }
  
          let action = UIAlertAction(
              title: "Delete",
              style: .destructive
          ) { _ in
              self.deleteHandler(identifier: identifier)
              handler()
          }
        
          let alert = AlertBuilder()
              .setTitle("진짜요?")
              .setMessage("정말로 삭제하시겠어요?")
              .setType(.alert)
              .setAction(action)
              .build()
        
          present(alert, animated: true)
      }
}
```
하지만 추후 새로운 ViewController를 구현했을때 showDeleteAlert() 메서드를 사용하지 않을경우 수정해야할 코드라고 생각되어 프로토콜을 사용하여 분리하였고 UIViewController를 상속받는 타입만 채택할수있도록 하여 present메서드도 프로토콜 내부에서 사용할수있도록 수정하였습니다.

```swift
protocol AlertProtocol: UIViewController {}

extension AlertProtocol {
    func showAlert(title: String, message: String, actions: [UIAlertAction]) {
        let alert = AlertBuilder.shared
            .setTitle(title)
            .setMessage(message)
            .setType(.alert)
            .setActions(actions)
            .build()
        
        present(alert, animated: true)
    }
}
```
하지만 이렇게 범용성있게 사용할수있도록 수정하여 사용하게될경우 Alert에서 사용될 action을 외부에서 정의해서 매개변수로 넣어주어야 합니다.

그렇게되면 Alert을 사용하는 ViewController 2곳에서 각각 액션을 정의해서 넣어주게되고 같은기능을 사용할경우 중복코드가 생기게됩니다.

하지만 이렇게 범용성있게 사용할수있도록 수정할경우 확장성에 좀더 용이하다고 판단되어 수정하였습니다.

최종적으로는 위와같이 수정하여 AlertProtocol을 채택하는 타입은 Alert을 사용할수있을거라 생각할수있게되고 자연스럽게 Alert과 관련된 메서드는 AlertProtocol에 정의되어있을것이라 생각할수있게됩니다.

9️⃣ **@objc 메서드**

selectro에서 사용되는 @objc 메서드에서 매개변수로 받을 수 있는 타입은 gesture 또는 sender에서 사용 가능한 UI 타입들(ex. UIButton) 입니다. 시스템에서 해당 메서드를 호출할 때 사용자 정의 타입은 넣을 수 없어서 메서드 구현에 제약이 많은 것 같습니다.

🔟 **tableView Cell의 swipe 액션에러**

테이블뷰의 Delegate메서드 trailingSwipeActionsConfigurationForRowAt() 를 사용하여
Alert을 띄우는 기능과 ActivityController를 띄우는 기능을 구현하였는데 Swipe 제스쳐를 사용한후 Delete 를 클릭후 cancel을 클릭하게될경우 Swipe가 해제되지 않는 버그가 발생했습니다.

![](https://i.imgur.com/NhOIH8p.gif)

```swift
    let delete = UIContextualAction(style: .destructive, title: "Delete") {
        [weak self] (_, _, completion) in
        self?.showAlert(title: "진짜요?",
                        message: "정말로 삭제 하시겠어요?",
                        actions: [cancelAction, deleteAction])
    }
            
    let share = UIContextualAction(style: .normal, title: "Share") {
        [weak self] (_, _, completion) in
        self?.showActivity(title: cellData.title)
    }
```
위의 코드에서 해당 작업이 끝났다는것을 알리기위해 completion(true) 코드를 추가하였습니다.
액션에 등록된 cancel버튼을 누르더라도 해당작업이 완료되도록 하여 문제를 해결했습니다.

```swift
    let delete = UIContextualAction(style: .destructive, title: "Delete") {
        [weak self] (_, _, completion) in
        self?.showAlert(title: "진짜요?",
                        message: "정말로 삭제 하시겠어요?",
                        actions: [cancelAction, deleteAction])
        completion(true)
    }
            
    let share = UIContextualAction(style: .normal, title: "Share") {
        [weak self] (_, _, completion) in
        self?.showActivity(title: cellData.title)
        completion(true)
    }
```

---
## 질문한것들
1️⃣ **파일 그룹화하는 방식**
파일을 쉽게 찾기 위해서 파일들을 묶는 방식에 대해 고민했습니다.
각 화면별로 그룹을 나누고 내부에서 사용되는 타입들을 구현 아키텍처에 맞게 MVC로 그룹화했습니다. 이때, AppDelegate, SceneDelegate를 Window라는 그룹에 넣었는데 더 좋은 그룹명이 있는지 궁금합니다.
또, Info, Diary, Asset, LaunchScreen은 어디에 그룹핑을 하는 것이 좋을지 고민입니다.

2️⃣ **삼항 연산자, nil 병합 연산자의 성능**
[관련 링크](https://code.iamseapy.com/archives/33)
삼함 연산자보다는 조건문이, nil 병합 연산자보다는 옵셔널 바인딩을 하는 것이 더 성능이 좋다고 하여 코드를 수정했습니다.

삼항 연산자와 nil 병합 연산자가 성능에 영향을 많이 주는지, 현업에서는 어떻게 사용되는지 궁금합니다!

3️⃣ **코어데이터 에러 처리**
CRUD 실패 시 에러를 어떻게 사용자에게 보여줄지 고민했습니다.
alert을 띄운다면 데이터 저장/수정 실패 시 백그라운에 진입해서 보여줄 수 없습니다. 또는 수정 페이지에서 이전화면(일기장 리스트화면)을 넘어가는 과정에서 저장/수정 실패 시 이전화면을 새로 띄우면서(일기장 리스트화면으로 돌아가는 것을 막으면서?) alert을 보이는 것이 이상하다고 생각했습니다. textView edit mode가 아닐 때 (`textViewDidEndEditing`매서드)의 저장/수정 실패 에러 처리만 가능할 것 같습니다.

코어데이터의 에러처리를 어떻게 하는 것이 좋을지 고민중입니다.😢

4️⃣ **메서드 역할 분리**
UpdateViewController에 있는 dataSave()의 경우 create와 update가 같이 사용해서 내부 로직이 뷰 컨에게 노출된 상태였습니다.

해당 뷰컨트롤러의 용도를 Mode 타입을 통해 구분하려면 특정 타입에서(DiaryViewcontroller와 UpdateViewController) 사용하도록 한정하는 것이 필요하다고 생각했습니다. 그러나 protocol을 통해 extension에서 기본구현을 사용해서 타입을 정의할 수 없습니다. 또, viewController의 추상클래스를 만들어서 두 뷰 컨트롤러가 상속받도록 하는 형식은 적절하지 않은 것 같습니다.
따라서, DiaryDAO.shared.save(data, isNew: true)와 같은 메서드를 통해 로직 자체를 viewController가 아닌 DiaryDAO에서 처리하도록 수정했습니다.
```swift
func save(_ newData: DiaryDTO?, isNew: Bool) {
        if isNew {
            create(userData: newData)
        } else {
            update(userData: newData)
        }
    }
```
위 메서드 구현으로 create, update 메서드를 은닉화할 수 있습니다.
