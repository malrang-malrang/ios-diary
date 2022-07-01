# 📒 일기장
> 프로젝트 기간 2022.06.13 ~ 2022.07.01  
팀원 : [malrang](https://github.com/malrang-malrang) [Tiana](https://github.com/Kim-TaeHyun-A) / 리뷰어 : [stevenkim](https://github.com/stevenkim18)

- [실행화면](#실행화면)
- [STEP 3 구현](#step-3-구현)
    + [고민했던 것들(트러블 슈팅)](#고민했던-것들트러블-슈팅)
    + [질문한것들](#질문한것들)
    
## 실행화면
<img src="https://i.imgur.com/gXsywNE.gif" width="240"><img src="https://i.imgur.com/CO9T9Sx.gif" width="240"><img src="https://i.imgur.com/dukLNU2.gif" width="240">

## STEP 3 구현
## 고민했던 것들(트러블 슈팅)

1️⃣ **MVC 아키텍처에 맞게 역할 분리**  


1. **변경 전후의 코드 비교: 커밋내역**


- [refactor: DiaryDataSource, DiaryTableView 커스텀 타입 구현](https://github.com/yagom-academy/ios-diary/pull/27/commits/f9d792ddf033ff7d272d17a5f79094ac9a3b8a1f#diff-0750dfcb7d5c73b8ed5a7346bf47c88e3f9fddd09938586c0b1d6f08394590d9)
- [refactor: DiaryTextView 구현](https://github.com/yagom-academy/ios-diary/pull/27/commits/2bab07567b481818b910770e735d4ff45821de2b)
- [refactor: DiaryViewController navigationController분리](https://github.com/yagom-academy/ios-diary/pull/27/commits/ccfb2f18401056a4ef185c97872300b87e72eab0)

2. **변경전의 구조**


    ![](https://i.imgur.com/I02upmi.png)

    ViewController가 별도의 view 프로퍼티로 가지지 않도록 controller와 view의 역할을 분리했습니다.
    UIViewController의 기본 프로퍼티인 view에 커스텀 view를 할당하고 view의 요소가 필요할 때는 메서드를 통해 간접적으로 접근합니다.


* **DiaryViewController과 DiaryView, tableView, DiaryViewModel, dataSource**


    DiaryViewController의 경우, 커스텀 view(DiaryView)의 tableView의 dataSource 설정이 필요해서 DiaryViewModel를 구현했습니다. view와 관련된 모델이라는 생각으로 viewModel이라는 네이밍을 했습니다.
DiaryViewController는 프로퍼티로 DiaryViewModel을 가지고 tableView는 매개변수로 접근하도록 구현했습니다.(viewController의 view가 이미 tableView를 프로퍼티로 가지기 때문에 viewModel이 굳이 tableView를 프로퍼티로 가지지 않아도 된다고 생각합니다. 또한 model에 view를 가지면 제대로 역할 분리가 되지 않았다고 생각합니다.)

* **DiaryCell과 WeatherAPIManager**


    DiaryCell에서 이미지를 로드할 때 url을 알 필요가 없습니다. 따라서, 네크워크를 관리하는 타입인 WeatherAPIManager를 extension하고 이미지를 받아오는 메서드를 구현했고(setImage 메서드) view에서는 메서드 호출 시 icon 문자열만 넘겨주면 이미지를 세팅할 수 있습니다. WeatherAPIManager의 메서드(setImage 메서드)를 호출하는 부분도 셀이 알 필요는 없을 것 같아서 UIImageView에 메서드를 구현해서 숨겼습니다.

* **UpdateViewController과 UpdateView, keyboard**


    UpdateViewController에서도 view를 따로 분리해서(UpdateView) keyboard 프로퍼티를 view만 가질 수 있습니다.
    

3. **변경후의 구조**


    ![](https://i.imgur.com/ORMIYdS.png)

    각각의 ViewController(DiaryViewController의)에서 사용되는customView(DiaryView)는 내부에서 tableView를 프로퍼티로 갖고 tableView를 화면에 보여주기 위한 기능들만 가지고있기에 customView를 활용하기보다는 tableView자체를 custom하도록 수정하였습니다.

- 3-1 **customView, tableView**


    **변경전 customView**

    ```swift
    final class DiaryView: UIView {
        private let tableView: UITableView = {
            let tableView = UITableView()
            
            tableView.translatesAutoresizingMaskIntoConstraints = false

            return tableView
        }()
    ```

    **변경후 customTableView**
    
    ```swift
    final class DiaryTableView: UITableView {}
    ```
    위와 동일한 방식으로 UpdateViewController에서 사용되는 textView도 custom하여 구현하였습니다.

    DiaryViewController에서 사용되던 DiaryViewModel또한 내부에서 사용되던 UITableViewDiffableDataSource를 custom하여 구현하도록 수정하였습니다.


- 3-2 **viewModel과 datasource**

    **변경전 DiaryViewModel**
    
    ```swift
    final class DiaryViewModel {
        private var dataSource: UITableViewDiffableDataSource<Int, DiaryDTO>?
    }
    ```


    **변경후 datasource**
    
    ```swift
    final class DiaryDataSource: UITableViewDiffableDataSource<Int, DiaryDTO> {}
    ```
    기존 변경 전 코드에서는 DiaryView, DiaryViewModel 내부의 private tableView, private dataSource에 접근하기위해 각각 tableView를 반환하는 메서드, dataSource를 반환하는 메서드 를 사용하여 활용했지만 구조와 타입을 변경하여 dataSource의 메서드들이 tableView를매개변수로 받지 않아도 작동하도록 변경, DiaryView내부의 tableView에 접근하지 않고 직접 tableView를 활용하는 방식으로 수정되었습니다.


    **변경전 DiaryViewController의 datasource관련 로직**
    
    ```swift
    final class DiaryViewController: UIViewController, DiaryProtocol {
        private let viewModel = DiaryViewModel()
        
        private var diaryView: DiaryView? {
            guard let view = view as? DiaryView else {
                return nil
            }
            return view
        }
    override func viewWillAppear(_ animated: Bool) {
            viewModel.updataTableView(tableView: diaryView?.getTableView())
        }
    }
    ```

    **변경후 DiaryViewController의 datasource관련 로직**
    
    ```swift
    final class DiaryViewController: UIViewController, DiaryProtocol {
        ...    
        private lazy var dataSource = DiaryDataSource(tableView: tableView) {
            tableView, indexPath, itemIdentifier in
            return self.setUpDataSource(tableView: tableView,
                                        indexPath: indexPath,
                                        itemIdentifier: itemIdentifier)
        }
        
        override func viewDidLoad() {
            super.viewDidLoad()
                    
            ...
            
            #if DEBUG
                dataSource.setUpSampleData()
            #else
                dataSource.setUpCoreData()
            #endif
        }
        ...
    }
    ```

    DiaryViewController, UpdateViewController에서 사용되는 NavigationController 관련 로직들은 DiaryViewController, UpdateViewController에서 각각의 파일 내부에 UINavigationController를 extension하여 구현하도록 수정했습니다.

- 3-3 **viewController의 NavigationController**

    **변경전 DiaryViewController의 NavigationController관련 로직**
    
    ```swift 
    final class DiaryViewController {
        enum Const {
            static let navigationTitle = "일기장"
            static let registerButton = "+"
        }
            private func setUpNavigationController() {
            func setUpRightItem() {
                let weight = UIFont.systemFont(ofSize: 35, weight: .light)
                let attributes = [NSAttributedString.Key.font: weight]
                let registerButton = UIBarButtonItem(
                    title: Const.registerButton,
                    style: .plain,
                    target: self,
                    action: #selector(moveRegisterViewController)
                )
                
            registerButton.setTitleTextAttributes(attributes, for: .normal)
            
            navigationItem.rightBarButtonItem = registerButton
            }
            
            navigationItem.title = Const.navigationTitle
            setUpRightItem()
        }
    
        @objc private func moveRegisterViewController() {
            let viewContoller = UpdateViewController()
            
            navigationController?.pushViewController(viewContoller, animated: true)
        }
    
    }
    ```


    **변경후 UINavigationController extension**
    
    ```swift
    private extension UINavigationController {
        private enum Const {
            static let navigationTitle = "일기장"
            static let registerButton = "+"
        }
        
        func setUpNavigationController(viewController: UIViewController) {
            func setUpRightItem() {
                let weight = UIFont.systemFont(ofSize: 35, weight: .light)
                let attributes = [NSAttributedString.Key.font: weight]
                let registerButton = UIBarButtonItem(
                    title: Const.registerButton,
                    style: .plain,
                    target: self,
                    action: #selector(moveRegisterViewController)
                )
                
                registerButton.setTitleTextAttributes(attributes, for: .normal)
                
                viewController.navigationItem.rightBarButtonItem = registerButton
            }
            
            viewController.navigationItem.title = Const.navigationTitle
            setUpRightItem()
        }
        
        @objc private func moveRegisterViewController() {
            let viewContoller = UpdateViewController()
            
            pushViewController(viewContoller, animated: true)
        }
    }
    ```


2️⃣ **iOS App 특정 HTTP 접근 허용방법**
프로젝트를 진행 하는데 ATS(App Transport Security) 라는 에러가 발생했다.

네트워크 통신중에 발생한 에러인데 요녀석이 뭔지 찾아보니 IOS9 버전 이후부터는 보안에 취약한 네트워크를 차단한다고 한다.

그래서 아무 설정없이 HTTP 에 접근하면 콘솔창에 App Transport Security 라고 하는 에러가 나오게되는데 Info.plist를 수정해 HTTP접근을 허용해주어야 한다!

아래의 사진처럼 특정 HTTP의 주소를 기재해주면 된다!

![](https://i.imgur.com/ZfYDO15.png)
```
주의사항

Allow Arbitary Loads 의 값을 YES 로 설정하고, Exception Domains에값이
없다면 모든 HTTP 통신을 허용하게된다.
```

## 질문한것들

1️⃣ **새로 작성된 데이터와 수정된 데이터를 리스트에서 어떻게 보여줄까🤔**

데이터 작성 페이지에서 목록 페이지로 넘어올 때 코어 데이터의 내용을 전부 읽어서 테이블 리스트를 보여주려니 코어데이터로 접근하는 시점 문제가 생겼습니다. 데이터 저장 완료되지 않는 상태에서 데이터를 가져와서 읽으려니 셀의 위치가 움직이고 새로 추가한 데이터가 바로 나타나지 않았습니다.(수정한 경우는 잘 반영 되었습니다.)

* #### 시행착오
    * 시도 1: 코어데이터 접근은 최초 리스트 페이지 로딩 때만 시도하고 이후는 snapshot을 활용한다.
    * 시도 2: 데이터를 1초 후에 읽어온다.
    * 시도 3: 데이터가 다 저장되면 코어데이터에서 읽어오도록 데리게이트 패턴을 사용( `최종 수정 결과!`)

* #### 최종 리팩토링 결과
시도 1은 실패했고 시도 2로 구현했으나 불필요하게 사용자가 기다려야 하는 경우(수정의 경우 빨리 데이터가 업데이트되어서 1초를 기다릴 필요 X) UX가 나쁠 것 같아서 시도 3으로 리팩토링했습니다.

* #### (시도1) 스냅샷 적용 과정 시의 문제사항
coreData를 최초에 목록페이지를 불러올 때(viewDidLoad()에서) 한 번만 load하고 이후부터는 snapshot을 수정해서 데이터를 테이블에 반영하고 싶었습니다.

이를 해결하기 위해 데이터를 추가하면 코어데이터에서 가져오는 것이 아니라 작성 페이지에서 추가한 데이터를 바로 데이터를 넘기고 싶습니다. 추가한 데이터를 이전 화면의 스냅샷에 추가하는 것은 아래 작성한 코드로 성공했습니다.
그렇지만 수정하는 경우는 아래의 에러가 발생합니다.😢

> Invalid item identifier specified for reload: Diary.DiaryDTO(identifier: ED4AB649-9DF0-40CB-87D8-EA7210C03F9E, title: \"Koopoo\", body: \"\", date: 2022-06-27 15:00:00 +0000, icon: nil)"

```swift
protocol UpdateProtocol: UIViewController {
    func updateList(data: DiaryDTO)
    func edit(data: DiaryDTO)
}

final class UpdateViewController {
    private weak var delegate: UpdateProtocol?
    
    init(diaryData: DiaryDTO? = nil, delegate: UpdateProtocol) {
        self.diaryData = diaryData
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }
    
    private func saveData() {
        ...
        
        if isSavingData == false {
            DiaryDAO.shared.save(data, isNew: isNew)
            isSavingData = true
            if isNew {
                delegate?.updateList(data: data)
            } else {
                delegate?.edit(data: data)
            }
        }
    }
}

extension DiaryViewController: UpdateProtocol {
    func updateList(data: DiaryDTO) {
        currentSnapShot.appendItems([data])
        dataSource?.apply(currentSnapShot)
    }
    
    func edit(data: DiaryDTO) {
        currentSnapShot.reloadItems([data])//특정 아이템만 수정
        dataSource?.apply(currentSnapShot)
    }
}

final class DiaryViewController: UIViewController, DiaryProtocol {
    ...
    private var currentSnapShot = NSDiffableDataSourceSnapshot<Int, DiaryDTO>()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ...
        
        currentSnapShot.appendSections([.zero])
        
        setUpCoreData() //ViewWillAppear에서 하던 것 여기로 이동
    }
    
    ...
    
    private func setUpSnapshot(data: [DiaryDTO]) {//프로퍼티 snapshot 이용
        currentSnapShot.appendItems(data)
        dataSource?.apply(currentSnapShot)
    }
}
```

만약 일기장 추가 시에는 추가 페이지에서 데이터를 넘겨서 그 정보만 스냅샷에 반영해서 리스트를 보여주고 일기장 수정 시에는 코어데이터에서 특정 데이터만 읽어오고 스냅샷에 append 시키면, 수정 시 기존 셀이 리스트에 그대로 남아있는 문제가 생깁니다.

* #### (시도1) 스냅샷 적용 과정 시의 결론
스냅샷이 내부적으로 차이를 비교해서 변경된 사항만 알아서 교체하기 때문에 수정된 것을 반영하려면 새로운 스냅샷을 적용해야 합니다.(즉, 특정 아이템 교체만 불가능한 것 같습니다.)
따라서, 기존의 방식처럼 코어데이터에서 데이터를 직접 읽어서 새로 적용하는 것이 가장 좋은 방법인 것 같다고 생각했습니다.

* #### (시도2) 1초 딜레이
1초 후 코어데이터에서 데이터를 읽어오도록 구현했습니다.
이때의 문제점은 네트워크 환경에 따라 유동적이 반응이 어렵습니다. 데이터를 불러오는 시간이 1초 이상 되는 경우 리스트와 코어데이터의 싱크가 맞지 않습니다. 또한 1초보다 빨리 데이터를 불러 올 수 있는 경우도 늘 사용자는 1초를 기다려야 합니다.
```swift
func updataTableView(tableView: UITableView?) {
        guard let tableView = tableView else {
            return
        }
        
        tableView.refreshControl?.beginRefreshing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.setUpCoreData(tableView: tableView)
        }
    }
```

* #### (시도3) 델리게이트 패턴
네트워크로 데이터를 받아오면 save 메서드를 통해 코어 데이터에 저장합니다. 저장 자체는 빨리 진행되어서 저장 메서드 호출 후 UI 업데이트 메서드를 호출하도록 구현했습니다.
```swift
protocol DataSourceDelegate: AnyObject {
    func updatePage()
}

extension DiaryViewController: DataSourceDelegate {
    func updatePage() {
        dataSource.setUpCoreData(tableView: tableView)
    }
}

final class DiaryDAO {
    ...
    private func create(userData: DiaryDTO?) {
        ...
        
        WeatherAPIManager.shared.fetchData(url: EntryPoint.weatherDescription(lat: lat, lon: lon).url) { [weak self] data in
            guard let data = try? data.get(),
                  let weather: WeatherDTO = data.convert() else {
                return
            }
            
            setUpCoreData(at: userModel, textData: userData, weatherData: weather)
            self?.save()
        }
    }
    ...
    private func save() {
        guard viewContext.hasChanges else {
            return
        }
        
        do {
            try viewContext.save()
            delegate?.updatePage()
        } catch let error {
            print("Error: \(error)")
        }
    }
    ...
}
```

2️⃣ **기능 요구서의 마이그레이션🤔** 
https://developer.apple.com/documentation/coredata/using_lightweight_migration

일기장 프로젝트를 진행하면서 entity에 attribute를 추가해야 하는 상황이 발생했습니다.
공식 문서를 읽어보면 entity 모델이 수정 사항이 있을때 마이그레이션을 해야한다고 작성되어있습니다!

**마이그레이션 이란?**
"데이터베이스의 스키마를 최신 또는 이전 버전으로 업데이트하거나 되돌릴 필요가 있을 때마다 데이터베이스에서 수행되는 과정"

![](https://i.imgur.com/PFl2ld7.png)

![](https://i.imgur.com/Hm2ycJF.png)

구글링하여 검색해보니 attribute를 수정하거나 추가할경우 버젼을 나누어 관리해야한다는 글을 봤습니다!

데이터 베이스가 수정될경우 에러가 발생하게되어 앱을 사용하던유저는 에러를 해결하기위해서는 앱을 제거후 재설치를 해야되는상황이 발생되기때문인데 이를 해결하기위해 마이그레이션을 해주는것 같습니다.

예를 들면 앱의 버전을 추가하여(예를들면 기존앱의 버전은 1, 데이터베이스 수정후는 2) 버전이 2보다 낮은경우 버전을 2로 수정 하는 작업을 하는것 같습니다!

하지만 저희 프로젝트에서 entity에 attribute를 추가했음에도 에러가 발생되지 않았고 앱의 UI를 변경했기때문에 데이터베이스의 에러와 상관없이 유저는 앱을 업데이트 해야한다고 생각되어 해당 기능을 구현하지 않았습니다.

3️⃣ 테스트 코드 표현하는 방법

릴리즈 모드일 때는 수행하지 않지만 테스트할 때 사용하고 싶은 코드의 경우 전처리 구문을 사용했습니다. 주석으로 표기하는 것보다 더 가독성이 좋고 명확하게 DEBUG 모드 코드임을 알릴 수 있습니다.

![](https://i.imgur.com/GqVNJaH.png)

```swift
#if DEBUG
    dataSource.setUpSampleData()
#else
    dataSource.setUpCoreData(tableView: tableView)
#endif
```



