# Лабораторна робота №1: Аналіз, вимоги, життєвий цикл та архітектурне бачення
Проєкт: DormHelper — Вебсистема обліку та обробки заявок на обслуговування і ремонт у студентському гуртожитку.

---

## 1. Формування вимог

### 1.1. Опис бізнес-ідеї
Проблема: У студентському гуртожитку заявки на ремонт (несправна сантехніка, вибиті автомати/електрика, проблеми з мережею, заміна меблів чи видача інвентарю) зазвичай подаються хаотично: у приватних Telegram-чатах, на словах черговому на вахті або в паперовому журналі. Через це звернення губляться, пріоритети незрозумілі, студенти не бачать статусу своєї заявки, а комендант гуртожитку не має об'єктивної статистики несправностей і навантаження на майстрів.

Рішення: Вебпортал DormHelper, який забезпечує централізований прийом, маршрутизацію та контроль виконання заявок у гуртожитку. Студент створює заявку із зазначенням кімнати, категорії та фотографії проблеми, майстер або комендант бере її в роботу та оновлює статус, а система зберігає повну історію робіт та формує аналітику по блоках і типах поломок.

### 1.2. Функціональні вимоги (User Stories)

#### Роль: Студент (Мешканець гуртожитку)
- US-01 (Авторизація): Як студент, я хочу авторизуватися через корпоративну пошту університету (SSO / OAuth2), щоб система автоматично підтягувала мій гуртожиток та номер кімнати.
- US-02 (Створення заявки): Як студент, я хочу створити заявку з описом проблеми, вибором категорії (сантехніка, електрика, інтернет, меблі/інше), пріоритету та фотографією, щоб майстер заздалегідь розумів характер несправності.
- US-03 (Відстеження статусу): Як студент, я хочу переглядати список своїх заявок і їхній поточний статус (*Нова*, *Прийнята*, *В роботі*, *Очікує деталей*, *Виконана*, *Відхилена*) та отримувати сповіщення про зміни.
- US-04 (Підтвердження виконання): Як студент, я хочу підтвердити закриття заявки після ремонту або повернути її на доопрацювання та залишити оцінку якості роботи.

#### Роль: Майстер / Черговий технік
- US-05 (Черга завдань): Як майстер, я хочу бачити призначені мені або відкриті заявки за своєю спеціалізацією та пріоритетом, щоб планувати обхід кімнат.
- US-06 (Оновлення статусу та коментарі): Як майстер, я хочу змінювати статус заявки, додавати технічні коментарі (наприклад, *«потрібна заміна змішувача»*) та фіксувати витрачені матеріали.

#### Роль: Комендант / Адміністратор гуртожитку
- US-07 (Управління заявками та виконавцями): Як комендант, я хочу переглядати всі заявки по гуртожитку, призначати відповідальних майстрів і підвищувати пріоритет аварійних інцидентів.
- US-08 (Аналітика та довідники): Як комендант, я хочу переглядати звіти за категоріями поломок і середнім часом виконання заявок, а також оновлювати довідники кімнат і виконавців.

---

## 2. Нефункціональні вимоги (НФВ / NFR) та їхній вплив на DevOps

Нефункціональні вимоги безпосередньо визначають архітектуру інфраструктури та інструменти DevOps-інженера:

| Категорія НФВ | Опис вимоги та цільові метрики | Вплив на архітектуру та вибір DevOps-інструментів |
| :--- | :--- | :--- |
| 1. Масштабованість (Scalability) | Навантаження на систему має хвильовий характер: під час поселення та початку семестру трафік зростає у $8\text{--}10$ разів (до $1500$ активних мешканців, пікова швидкість запитів — до $150\text{ RPS}$), а також спостерігаються щоденні вечірні піки ($18:00\text{--}22:00$). | • Контейнеризація та оркестрація: Використання Docker та Kubernetes (K8s) з налаштованим *Horizontal Pod Autoscaler (HPA)* за метриками CPU/RAM.<br>• Stateless-архітектура: Винесення фотографій несправностей у об'єктне сховище S3 / MinIO, щоб репліки бекенду залишалися безстановими та масштабувалися миттєво.<br>• Кешування: Використання Redis для кешування довідників кімнат, категорій та частих запитів списку заявок. |
| 2. Доступність та надійність (Availability) | Рівень доступності сервісу має становити $SLA \ge 99.5\%$ (допустимий простій не більше $3.65$ год/місяць). Втрата зареєстрованих заявок та фотофіксації недопустима ($RPO < 1\text{ год}$, $RTO < 30\text{ хв}$). | • База даних: Кластер PostgreSQL у конфігурації Primary-Replica з автоматичним перемиканням (Failover).<br>• Zero-Downtime Deployment: Використання стратегії *RollingUpdate* у Kubernetes під час викатки нових релізів через GitHub Actions.<br>• Резервне копіювання: Автоматизовані щоденні снепшоти БД та версіонування бакетів в S3. |
| 3. Безпека (Security) | Доступ до системи мають лише верифіковані мешканці та персонал гуртожитку за протоколом HTTPS ($TLS\ 1.3$). Реалізується суворе розмежування прав доступу (RBAC: Студент, Майстер, Комендант) та перевірка завантажених зображень. | • Валідація файлів та RBAC: Перевірка MIME-типів і розміру фото на рівні API та обмеження доступу до чужих заявок.<br>• DevSecOps у CI/CD: Автоматичне сканування коду (ESLint / SonarQube), залежностей та Docker-образів (Trivy) на вразливості.<br>• Секрети та мережа: Зберігання паролів і ключів у K8s Secrets / GitHub Secrets, випуск TLS-сертифікатів через cert-manager (Let's Encrypt). |
| 4. Спостережуваність (Observability) | Час відповіді API для $95\%$ запитів не має перевищувати $p_{95} \le 250\text{ мс}$. Команда повинна бачити стан черги сповіщень та отримувати алерти про помилки $5\text{xx}$ за $\le 1\text{ хв}$. | • Метрики та алертинг: Збір метрик інфраструктури та додатку за допомогою Prometheus, візуалізація у Grafana, сповіщення в Telegram через Alertmanager.<br>• Централізоване логування: Стек Grafana Loki + Promtail для збору структурованих логів з усіх контейнерів.<br>• Трейсинг: OpenTelemetry для відстеження затримок між API, БД та S3. |

---

## 3. Життєвий цикл та методологія розробки

### 3.1. Перехід від класичних моделей (Waterfall / RUP) до Agile + DevOps
У класичних методологіях, таких як каскадна модель (Waterfall) або традиційний Rational Unified Process (RUP), життєвий цикл поділявся на послідовні фази (*Inception, Elaboration, Construction, Transition*).
- Недоліки RUP для системи DormHelper: Розробники (Dev) тривалий час реалізовували б функціонал у фазі *Construction*, після чого передавали б артефакти системним адміністраторам (Ops) на фазі *Transition*. Це створювало «стіну непорозуміння»: розбіжності в налаштуваннях середовищ, міграціях бази даних або правах доступу до сховища файлів виявлялися занадто пізно, а зміни в логіці статусів заявок потребували довгого циклу узгоджень.

### 3.2. Обрана методологія: Agile (Scrum) з інтеграцією DevOps
Для розробки DormHelper обрано ітеративну методологію Scrum (тривалість спринту — 2 тижні) у поєднанні з практиками DevOps та Continuous Delivery (Безперервна доставка):

1. Plan & Design (Architecture as Code): На початку спринту нові вимоги та зміни архітектури фіксуються у вигляді коду (Mermaid/Structurizr DSL) та ADR безпосередньо в Git-репозиторії.
2. Code & Shift-Left Testing: Розробники працюють у коротких гілках (*Feature Branches* / *GitHub Flow*). Локальне середовище повністю ідентичне продакшену завдяки docker-compose.
3. Continuous Integration (CI): При кожному *Pull Request* автоматично запускається пайплайн (GitHub Actions):
   - Лінтери та статичний аналіз коду (ESLint, Hadolint).
   - Юніт- та інтеграційні тести (з підняттям тестової PostgreSQL у контейнері).
   - Збірка Docker-образу та його сканування на вразливості (Trivy).
4. Continuous Delivery / Deployment (CD):
   - Після злиття в гілку main образ публікується в GitHub Container Registry (GHCR).
   - Інфраструктура описується декларативно (Infrastructure as Code — Docker Compose / Helm-чарти).
   - Оновлення автоматично розгортаються на *Staging*, а після перевірки працездатності (Healthchecks / Smoke Tests) — на *Production*.
5. Operate & Monitor: Зворотний зв'язок із Prometheus/Grafana дозволяє команді відстежувати реальне навантаження під час поселення студентів та планувати оптимізації на наступний спринт.

---

## 4. Архітектурне проєктування (Модель C4 та 4+1 Deployment View)

> Примітка: Діаграми нижче описані за допомогою Mermaid.js відповідно до підходу *Architecture as Code (AaC)*. Також у репозиторії міститься файл architecture.dsl для генерації діаграм через Structurizr.

### 4.1. C4 Рівень 1: Контекстна діаграма системи (System Context)
Показує систему DormHelper у центрі та її взаємодію з користувачами й зовнішніми сервісами.

~~~mermaid
flowchart TB
    %% Актори
    Student(["<b>Студент</b><br/>[Person]<br/>Мешканець гуртожитку. Створює заявки на ремонт та відстежує їх статус"])
    Master(["<b>Майстер / Черговий</b><br/>[Person]<br/>Приймає заявки за своєю спеціалізацією, виконує роботи та оновлює статус"])
    Admin(["<b>Комендант / Адміністратор</b><br/>[Person]<br/>Керує чергами заявок, призначає виконавців та переглядає аналітику"])

    %% Основна система
    DormHelper["<b>Система DormHelper</b><br/>[Software System]<br/>Вебплатформа для централізованого обліку, маршрутизації та контролю заявок у гуртожитку"]

    %% Зовнішні системи
    UniSSO["<b>Університетський SSO (OAuth2)</b><br/>[External System]<br/>Автентифікація мешканців і персоналу та передача даних про кімнату"]
    NotifySys["<b>Сервіс сповіщень (Telegram API / SMTP)</b><br/>[External System]<br/>Надсилання повідомлень про створення та зміну статусу заявки"]

    %% Зв'язки
    Student -->|"Створює заявки, завантажує фото та перевіряє статус (HTTPS)"| DormHelper
    Master -->|"Оновлює статус робіт та додає коментарі (HTTPS)"| DormHelper
    Admin -->|"Призначає майстрів, керує довідниками та звітами (HTTPS)"| DormHelper
    DormHelper -->|"Автентифікує користувачів (OIDC / OAuth 2.0)"| UniSSO
    DormHelper -->|"Надсилає сповіщення користувачам (HTTPS / SMTP)"| NotifySys

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef system fill:#1168bd,stroke:#0b4884,color:#ffffff
    classDef external fill:#999999,stroke:#6b6b6b,color:#ffffff

    class Student,Master,Admin person
    class DormHelper system
    class UniSSO,NotifySys external
~~~

---

### 4.2. C4 Рівень 2: Діаграма контейнерів (Container Diagram)
Розкриває внутрішню будову системи DormHelper на рівні окремо розгортуваних одиниць (контейнерів).

~~~mermaid
flowchart TB
    Users(["<b>Студент / Майстер / Комендант</b><br/>[Person]"])

    subgraph DormHelper_Boundary ["Межі системи DormHelper"]
        SPA["<b>Single-Page Application</b><br/>[Container: React / TypeScript]<br/>Надає веб-інтерфейс для подачі заявок, перегляду черги та аналітики"]
        API["<b>Core Backend API</b><br/>[Container: Node.js / NestJS]<br/>Обробляє бізнес-логіку, RBAC-авторизацію, статуси заявок та валідацію"]
        Worker["<b>Notification & Report Worker</b><br/>[Container: Node.js / BullMQ Worker]<br/>Асинхронно відправляє сповіщення та генерує періодичні звіти"]
        
        DB[("<b>Relational Database</b><br/>[Container: PostgreSQL 16]<br/>Зберігає користувачів, кімнати, заявки, історію статусів і коментарі")]
        Cache[("<b>In-Memory Cache & Queue</b><br/>[Container: Redis 7]<br/>Кешує довідники кімнат/категорій та зберігає чергу фонових задач")]
        S3[("<b>Object Storage</b><br/>[Container: MinIO / AWS S3]<br/>Зберігає фотографії несправностей, прикріплені до заявок")]
    end

    UniSSO["<b>Університетський SSO</b><br/>[External System]"]
    NotifySys["<b>Telegram API / SMTP</b><br/>[External System]"]

    %% Взаємодія
    Users -->|"Працюють із заявками через браузер (HTTPS)"| SPA
    SPA -->|"Викликає REST API (JSON/HTTPS)"| API
    SPA -->|"Завантажує фото напряму за Pre-signed URLs (HTTPS)"| S3

    API -->|"Читає та записує заявки і статуси (TCP/SQL)"| DB
    API -->|"Кешує довідники та ставить задачі в чергу (TCP)"| Cache
    API -->|"Генерує Pre-signed URLs для доступу до фото (S3 API)"| S3
    API -->|"Перевіряє токени авторизації (HTTPS)"| UniSSO

    Worker -->|"Бере задачі з черги подій (TCP)"| Cache
    Worker -->|"Читає дані для формування звітів (TCP/SQL)"| DB
    Worker -->|"Надсилає сповіщення про зміну статусу (HTTPS)"| NotifySys

    classDef person fill:#08427b,stroke:#052e56,color:#ffffff
    classDef container fill:#438dd5,stroke:#2e6295,color:#ffffff
    classDef db fill:#2b6cb0,stroke:#1a365d,color:#ffffff
    classDef external fill:#999999,stroke:#6b6b6b,color:#ffffff

    class Users person
    class SPA,API,Worker container
    class DB,Cache,S3 db
    class UniSSO,NotifySys external
~~~

---

### 4.3. Модель 4+1: Фізичний вигляд / Вигляд розгортання (Deployment View)
Показує, як програмні контейнери мапляться на хмарну інфраструктуру та кластер Kubernetes з урахуванням вимог масштабованості, безпеки та observability.

~~~mermaid
flowchart TB
    subgraph Client_Node ["Клієнтське середовище"]
        Browser["Веббраузер студента / майстра / коменданта"]
    end

    subgraph Cloud_Infra ["Хмарна інфраструктура (VPS / Cloud Provider)"]
        LB["<b>Cloud Load Balancer / Ingress NGINX</b><br/>[TLS Termination, Rate Limiting]"]

        subgraph K8s_Cluster ["Kubernetes Cluster (Production)"]
            subgraph App_Namespace ["Namespace: dormhelper-prod"]
                Frontend_Pods["<b>Deployment: Frontend SPA</b><br/>[Nginx + React Static]<br/>Replicas: 2"]
                API_Pods["<b>Deployment: Core Backend API</b><br/>[Node.js Container]<br/>HPA Replicas: 2..6"]
                Worker_Pods["<b>Deployment: Notification Worker</b><br/>[Background Worker]<br/>Replicas: 1..3"]
                Redis_Pod["<b>StatefulSet: Redis</b><br/>[Cache & Job Queue]"]
            end

            subgraph Monitoring_Namespace ["Namespace: observability"]
                Prom_Grafana["<b>Prometheus + Grafana + Loki</b><br/>[Збір метрик, логів та алертинг]"]
            end
        end

        subgraph Managed_Services ["Керовані сервіси зберігання (Managed Storage)"]
            PG_Cluster[("<b>Managed PostgreSQL</b><br/>[Primary + Standby Replica]<br/>Daily Backups")]
            S3_Bucket[("<b>S3 / MinIO Object Storage</b><br/>[Бакет фотографій заявок]")]
        end
    end

    Browser -->|"HTTPS (443)"| LB
    Browser -->|"HTTPS (Pre-signed URL)"| S3_Bucket
    LB -->|"HTTP (80)"| Frontend_Pods
    LB -->|"HTTP (3000) /api/*"| API_Pods

    API_Pods -->|"TCP (5432)"| PG_Cluster
    API_Pods -->|"TCP (6379)"| Redis_Pod
    API_Pods -->|"HTTPS (S3 API)"| S3_Bucket

    Worker_Pods -->|"TCP (6379)"| Redis_Pod
    Worker_Pods -->|"TCP (5432)"| PG_Cluster

    Prom_Grafana -.->|"Scrape /metrics & logs"| API_Pods
    Prom_Grafana -.->|"Scrape /metrics & logs"| Worker_Pods

    classDef infra fill:#e2e8f0,stroke:#475569,color:#0f172a
    classDef k8s fill:#326ce5,stroke:#1e40af,color:#ffffff
    classDef storage fill:#0f766e,stroke:#115e59,color:#ffffff
    classDef obs fill:#7c3aed,stroke:#5b21b6,color:#ffffff

    class Frontend_Pods,API_Pods,Worker_Pods,Redis_Pod k8s
    class PG_Cluster,S3_Bucket storage
    class Prom_Grafana obs
~~~

---

## 5. Журнал архітектурних рішень (Architecture Decision Records)

Усі архітектурні рішення зберігаються у каталозі docs/adr/:
1. [ADR-0001: Гібридна архітектура зберігання даних (PostgreSQL + S3 Object Storage)](docs/adr/adr_0001.md)
2. [ADR-0002: Асинхронна обробка сповіщень та фонових задач через Redis і Worker](docs/adr/adr_0002.md)
