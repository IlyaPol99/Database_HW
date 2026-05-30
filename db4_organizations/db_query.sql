/*
 Задача 1
 Найти всех сотрудников, подчиняющихся Ивану Иванову (с EmployeeID = 1),
 включая их подчиненных и подчиненных подчиненных, а также самого Ивана Иванова.

 Для каждого сотрудника вывести следующую информацию:
 EmployeeID: идентификатор сотрудника.
 Имя сотрудника.
 ManagerID: Идентификатор менеджера.
 Название отдела, к которому он принадлежит.
 Название роли, которую он занимает.
 Название проектов, к которым он относится (если есть, конкатенированные в одном столбце через запятую).
 Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце через запятую).
 Если у сотрудника нет назначенных проектов или задач, отобразить NULL.

 Требования:
 Рекурсивно извлечь всех подчиненных сотрудников Ивана Иванова и их подчиненных.
 Для каждого сотрудника отобразить информацию из всех таблиц.
 Результаты должны быть отсортированы по имени сотрудника.
 Решение задачи должно представлять из себя один sql-запрос и задействовать ключевое слово RECURSIVE.
 */

WITH RECURSIVE employee_hierarchy AS (
    SELECT EmployeeID, Name, ManagerID, DepartmentID, RoleID
    FROM Employees WHERE EmployeeID = 1
    UNION ALL
    SELECT e.EmployeeID, e.Name, e.ManagerID, e.DepartmentID, e.RoleID
    FROM Employees e
    INNER JOIN employee_hierarchy eh ON e.ManagerID = eh.EmployeeID
)
SELECT
    eh.EmployeeID,
    eh.Name AS EmployeeName,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    p.ProjectNames,
    t.TaskNames
FROM employee_hierarchy eh
LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON eh.RoleID = r.RoleID
LEFT JOIN (
    SELECT
        e.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM Employees e
    LEFT JOIN Projects p ON e.DepartmentID = p.DepartmentID
    GROUP BY e.EmployeeID
) p ON eh.EmployeeID = p.EmployeeID
LEFT JOIN (
    SELECT
        t.AssignedTo AS EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames
    FROM Tasks t
    GROUP BY t.AssignedTo
) t ON eh.EmployeeID = t.EmployeeID
ORDER BY eh.Name;

/*
 Задача 2
 Найти всех сотрудников, подчиняющихся Ивану Иванову с EmployeeID = 1, включая их подчиненных и подчиненных подчиненных,
 а также самого Ивана Иванова.

 Для каждого сотрудника вывести следующую информацию:
 EmployeeID: идентификатор сотрудника.
 Имя сотрудника.
 Идентификатор менеджера.
 Название отдела, к которому он принадлежит.
 Название роли, которую он занимает.
 Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
 Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
 Общее количество задач, назначенных этому сотруднику.
 Общее количество подчиненных у каждого сотрудника (не включая подчиненных их подчиненных).
 Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */

-- Рекурсивно находим всех подчиненных Ивана Иванова (EmployeeID = 1) и его самого
WITH RECURSIVE employee_hierarchy AS (
    -- Базовый запрос: начинаем с Ивана Иванова
    SELECT
        EmployeeID,
        Name,
        ManagerID,
        DepartmentID,
        RoleID
    FROM Employees
    WHERE EmployeeID = 1

    UNION ALL

    -- Рекурсивный запрос: находим подчиненных для каждого сотрудника из предыдущего уровня
    SELECT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    INNER JOIN employee_hierarchy eh ON e.ManagerID = eh.EmployeeID
),
direct_subordinates AS (
    -- Считаем количество прямых подчиненных для каждого сотрудника
    SELECT
        ManagerID,
        COUNT(*) AS subordinate_count
    FROM Employees
    WHERE ManagerID IS NOT NULL
    GROUP BY ManagerID
),
employee_projects AS (
    -- Проекты, к которым относится сотрудник (через отдел)
    SELECT
        e.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM Employees e
    LEFT JOIN Projects p ON e.DepartmentID = p.DepartmentID
    GROUP BY e.EmployeeID
),
employee_tasks AS (
    -- Задачи, назначенные сотруднику (названия и количество)
    SELECT
        t.AssignedTo AS EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames,
        COUNT(t.TaskID) AS TaskCount
    FROM Tasks t
    GROUP BY t.AssignedTo
)
SELECT
    eh.EmployeeID,
    eh.Name AS EmployeeName,
    eh.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.ProjectNames,
    et.TaskNames,
    COALESCE(et.TaskCount, 0) AS TotalTasks,
    COALESCE(ds.subordinate_count, 0) AS TotalSubordinates
FROM employee_hierarchy eh
LEFT JOIN Departments d ON eh.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON eh.RoleID = r.RoleID
LEFT JOIN employee_projects ep ON eh.EmployeeID = ep.EmployeeID
LEFT JOIN employee_tasks et ON eh.EmployeeID = et.EmployeeID
LEFT JOIN direct_subordinates ds ON eh.EmployeeID = ds.ManagerID
ORDER BY eh.Name;

/*
 Задача 3
 Найти всех сотрудников, которые занимают роль менеджера и имеют подчиненных (то есть число подчиненных больше 0).

 Для каждого такого сотрудника вывести следующую информацию:
 EmployeeID: идентификатор сотрудника.
 Имя сотрудника.
 Идентификатор менеджера.
 Название отдела, к которому он принадлежит.
 Название роли, которую он занимает.
 Название проектов, к которым он относится (если есть, конкатенированные в одном столбце).
 Название задач, назначенных этому сотруднику (если есть, конкатенированные в одном столбце).
 Общее количество подчиненных у каждого сотрудника (включая их подчиненных).
 Если у сотрудника нет назначенных проектов или задач, отобразить NULL.
 */

-- Рекурсивно находим всех подчиненных для каждого менеджера (включая подчиненных подчиненных)
WITH RECURSIVE all_subordinates AS (
    -- Базовый запрос: все сотрудники, которые являются менеджерами (имеют подчиненных)
    SELECT
        e.EmployeeID AS ManagerID,
        e.EmployeeID AS SubordinateID,
        1 AS level
    FROM Employees e
    WHERE EXISTS (SELECT 1 FROM Employees sub WHERE sub.ManagerID = e.EmployeeID)

    UNION ALL

    -- Рекурсивный запрос: находим подчиненных подчиненных
    SELECT
        asub.ManagerID,
        e.EmployeeID AS SubordinateID,
        asub.level + 1
    FROM all_subordinates asub
    JOIN Employees e ON e.ManagerID = asub.SubordinateID
),
subordinate_counts AS (
    -- Считаем количество всех подчиненных для каждого менеджера (включая подчиненных подчиненных)
    SELECT
        ManagerID,
        COUNT(DISTINCT SubordinateID) AS TotalSubordinates
    FROM all_subordinates
    WHERE ManagerID != SubordinateID  -- не считаем самого себя
    GROUP BY ManagerID
),
employee_projects AS (
    -- Проекты, к которым относится сотрудник (через отдел)
    SELECT
        e.EmployeeID,
        STRING_AGG(DISTINCT p.ProjectName, ', ' ORDER BY p.ProjectName) AS ProjectNames
    FROM Employees e
    LEFT JOIN Projects p ON e.DepartmentID = p.DepartmentID
    GROUP BY e.EmployeeID
),
employee_tasks AS (
    -- Задачи, назначенные сотруднику
    SELECT
        t.AssignedTo AS EmployeeID,
        STRING_AGG(DISTINCT t.TaskName, ', ' ORDER BY t.TaskName) AS TaskNames
    FROM Tasks t
    GROUP BY t.AssignedTo
),
managers AS (
    -- Сотрудники с ролью менеджера (RoleID = 1) и имеющие подчиненных
    SELECT DISTINCT
        e.EmployeeID,
        e.Name,
        e.ManagerID,
        e.DepartmentID,
        e.RoleID
    FROM Employees e
    WHERE e.RoleID = 1  -- Менеджер
      AND EXISTS (SELECT 1 FROM Employees sub WHERE sub.ManagerID = e.EmployeeID)
)
SELECT
    m.EmployeeID,
    m.Name AS EmployeeName,
    m.ManagerID,
    d.DepartmentName,
    r.RoleName,
    ep.ProjectNames,
    et.TaskNames,
    sc.TotalSubordinates
FROM managers m
LEFT JOIN Departments d ON m.DepartmentID = d.DepartmentID
LEFT JOIN Roles r ON m.RoleID = r.RoleID
LEFT JOIN employee_projects ep ON m.EmployeeID = ep.EmployeeID
LEFT JOIN employee_tasks et ON m.EmployeeID = et.EmployeeID
LEFT JOIN subordinate_counts sc ON m.EmployeeID = sc.ManagerID
ORDER BY m.Name;
