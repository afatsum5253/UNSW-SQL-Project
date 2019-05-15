-- comp9311 19s1 Project 1
--
-- MyMyUNSW Solutions


-- Q1:
create or replace view Q1(unswid, longname)
as
select distinct r.unswid as unswid, r.longname as longname from rooms r
inner join room_types rt on r.rtype = rt.id
inner join classes cl on r.id = cl.room
inner join courses co on co.id = cl.course
inner join semesters se on se.id = co.semester
inner join subjects sj on sj.id = co.subject
where se.year = 2013 and se.term = 'S1' and rt.description = 'Laboratory' and sj.code = 'COMP9311'
;

-- Q2:
create or replace view Q2(unswid,name)
as
select unswid, name from people where id in (
select st.staff from course_staff st 
inner join course_enrolments ce on st.course = ce.course
inner join people p on p.id = ce.student
where p.name = 'Bich Rae')
;

-- Q3:
create or replace view Q3(unswid, name)
as 
select unswid, name from people where id in(
select distinct p.id from course_enrolments ce
inner join courses co on ce.course = co.id
inner join semesters se on se.id = co.semester
inner join subjects sj on sj.id = co.subject
inner join students st on st.id = ce.student
inner join people p on p.id = st.id
where sj.code in ('COMP9021','COMP9311') and st.stype = 'intl'
group by p.id, se.unswid
having count(*) > 1)
;

-- Q4:

create or replace view StudentProgram as
select pe.program, pg.name, st.stype , count( distinct st.id) from program_enrolments pe
inner join students st on st.id = pe.student
inner join programs pg on pg.id = pe.program
group by pe.program, pg.name, st.stype; 

create or replace view Q4(code,name)
as
select code, name from programs where id in
(select tab.program from
(select program,name, sum(count) as total from StudentProgram
group by program, name) as tab,
(select program, count as intl_count from StudentProgram
where stype = 'intl'
group by program, name, count) as tab_intl
where tab.program = tab_intl.program
and (intl_count/total)*100 >= 30 and (intl_count/total)*100 <= 70)
;

--Q5:
create or replace view  maxi AS select course, min(mark)  from course_enrolments where mark IS NOT NULL group by course having count(mark)>20;

create or replace view Q5(code,name,semester)
as
select s.code, s.name, sem.name from subjects s, semesters sem, courses c 
where c.id  = (select course from maxi where min in (select max(min) from maxi)) and c.subject = s.id and c.semester = sem.id
;

-- Q6:
create or replace view Q6(num1, num2, num3)
as
select val1, val2, val3 from 
(select count(distinct unswid) as val1 from people where id in(
select distinct stu.id from program_enrolments pe
inner join stream_enrolments se on se.partof = pe.id                         
inner join semesters sem on sem.id = pe.semester                                                                   
inner join streams st on st.id = se.stream                                                       
inner join students stu on stu.id = pe.student                                                                                         
where stu.stype = 'local' and sem.year = 2010 and sem.term = 'S1' and st.name = 'Chemistry')) AS PA1,
(select count(distinct unswid) as val2 from people where id in(
select distinct stu.id from students stu
inner join program_enrolments pe on pe.student = stu.id
inner join semesters sem on sem.id = pe.semester
inner join programs po on po.id = pe.program
inner join orgunits ou on ou.id = po.offeredby
where stu.stype = 'intl' and sem.year = 2010 and sem.term = 'S1' and ou.name = 'Faculty of Engineering')) AS PA2,
(select count(distinct unswid) as val3 from people where id in(
select distinct stu.id from students stu
inner join program_enrolments pe on pe.student = stu.id
inner join semesters sem on sem.id = pe.semester
inner join programs po on po.id = pe.program
where sem.year = 2010 and sem.term = 'S1' and po.name = 'Computer Science' and po.code = '3978')) AS PA3
;

-- Q7:
create or replace view A AS 
(select * from affiliations where role = (select id from staff_roles where name = 'Dean') and isprimary='t');

create or replace view B AS 
(select A.orgunit,A.role,A.starting,A.ending,A.staff 
from A, course_staff c,courses,subjects,orgunits o, OrgUnit_types ot 
where A.staff = c.staff and c.course=courses.id and courses.subject=subjects.id and A.orgunit = o.id and o.utype = ot.id and ot.name='Faculty');

create or replace view Q7(name, school, email, starting, num_subjects)
as
select p.name,o.longname,p.email,B.starting,COUNT(distinct(sub.code)) 
from people p,B,staff s,orgunits o,courses c,course_staff cs,subjects sub 
where B.staff=s.id and s.id=p.id and B.orgunit=o.id and B.staff=cs.staff and cs.course=c.id and c.subject = sub.id 
group by p.name,o.longname,p.email,B.starting
;

-- Q8:
create or replace view bhum AS select ce.course from course_enrolments ce, students st where ce.student = st.id group by ce.course having count(distinct (st.id))>=20;

create or replace view Q8(subject)
as
select concat(s.code,' ', s.name) from bhum b,courses c,subjects s where b.course = c.id and c.subject = s.id group by s.name,s.code having count(distinct(b.course))>=20;
;

-- Q9:
create or replace view Studentenrol as
select og.id, se.year, count(distinct pe.student) as student_count from orgunits og 
inner join programs pg on pg.offeredby = og.id
inner join program_enrolments pe on pe.program = pg.id
inner join semesters se on se.id = pe.semester
inner join students st on st.id = pe.student
where st.stype = 'intl'
group by og.id, se.year;

create or replace view StudentEnrolMax as
select id, max(student_count) as student_count from Studentenrol
group by id;

create or replace view Q9(year,num,unit)
as
select year, student_count, longname from
(select se.id, se.year, se.student_count from StudentEnrolMax sem, StudentEnrol se
where sem.id = se.id and sem.student_count = se.student_count) PA1
inner join orgunits og on og.id = PA1.id
;

-- Q10:
create or replace view bhum2 as 
select p.unswid,p.name, cast(avg(ce.mark) as decimal(4,2)) 
from course_enrolments ce, courses c, people p 
where ce.course = c.id and ce.student = p.id and c.semester = 
(select id from semesters where year = 2011 and term ='S1') and ce.mark>=0 
group by p.unswid, p.name 
having count(ce.mark>=0)>=3 order by avg desc;

create or replace view Q10(unswid,name,avg_mark)
as
select * from bhum2 where avg>= (select min(avg) as avg from (select * from bhum2 limit 10) as bumi);
;

-- Q11:
create or replace view AcadStand as
select p.unswid, p.name, co.id, ce.mark from people p
inner join students st on st.id = p.id
inner join course_enrolments ce on st.id = ce.student
inner join courses co on co.id = ce.course
inner join semesters sem on sem.id = co.semester
where sem.term = 'S1' and sem.year = 2011 and p.unswid::text like '313%' and ce.mark> 0;

create or replace view AcadStandCourseCnt as
select unswid, count(distinct ac.id) as tot from AcadStand ac
group by unswid;

create or replace view AcadStandCoursePassCnt as
select unswid, count(distinct ac.id) as tot from AcadStand ac
where mark >= 50 
group by unswid;

create or replace view AcadStandCourseNet as
select pep.unswid, pep.name, coalesce(p.tot,0) as pass, t.tot as total from people pep
inner join AcadStandCourseCnt t on t.unswid = pep.unswid
left join AcadStandCoursePassCnt p on p.unswid = pep.unswid;

create or replace view Q11(unswid, name, academic_standing)
as
select unswid, name, standing from(
select unswid, name, 'Good' as standing from AcadStandCourseNet
where total = 1 and pass = 1
UNION
select unswid, name, 'Referral' as standing from AcadStandCourseNet
where total = 1 and pass = 0
UNION
select unswid, name, 'Good' as standing from AcadStandCourseNet
where total > 1 and cast(pass as decimal(4,2))/cast(total as decimal(4,2)) > 0.5
UNION
select unswid, name, 'Referral' as standing from AcadStandCourseNet                                                                                                                   
where total > 1 and cast(pass as decimal(4,2))/cast(total as decimal(4,2)) <=0.5 and  cast(pass as decimal(4,2))/cast(total as decimal(4,2)) > 0.0
UNION
select unswid, name, 'Probation' as standing from AcadStandCourseNet
where total > 1 and pass = 0) AA
;

-- Q12:

create or replace view StudentCompTot as
select sj.code, sj.name, sem.year, sem.term, count(ce.mark) as total_count from course_enrolments ce
inner join courses co on co.id = ce.course
inner join subjects sj on sj.id = co.subject
inner join semesters sem on sem.id = co.semester
where sj.code like 'COMP90%' and sem.term in ('S1','S2') and sem.year >= 2003 and sem.year <= 2012 and ce.mark >= 0
group by sj.code, sj.name, sem.year, sem.term;

create or replace view StudentCompPass as
select sj.code, sj.name, sem.year, sem.term, count(ce.mark) as total_count from course_enrolments ce
inner join courses co on co.id = ce.course
inner join subjects sj on sj.id = co.subject
inner join semesters sem on sem.id = co.semester
where sj.code like 'COMP90%' and sem.term in ('S1','S2') and sem.year >= 2003 and sem.year <= 2012 and ce.mark >= 50
group by sj.code, sj.name, sem.year, sem.term;

create or replace view StudentCompTotDummy2 as
select sj.code, sj.name, count(distinct sem.term) as total_count from course_enrolments ce
inner join courses co on co.id = ce.course
inner join subjects sj on sj.id = co.subject
inner join semesters sem on sem.id = co.semester
where sj.code like 'COMP90%' and sem.term in ('S1','S2') and sem.year >= 2003 and sem.year <= 2012
group by sj.code, sj.name
having count(distinct sem.term) = 2 and count(distinct sem.year) = 10;

create or replace view Q12(code, name, year, s1_ps_rate, s2_ps_rate)
as
select coalesce(ps2.code,ps1.code), coalesce(ps2.name,ps1.name)::text, substring(coalesce(ps2.year,ps1.year)::text from 3 for 2), coalesce(ps1.pass_s1), coalesce(ps2.pass_s2) from
(select t.code, t.name, t.year, CAST( CAST (p.total_count AS DECIMAL(4,2))/CAST (t.total_count AS DECIMAL(4,2)) AS DECIMAL(4,2)) as pass_s1 from
(select code, name, year, total_count  from StudentCompTot where code in (select code from StudentCompTotDummy2) and term = 'S1') t
left join
(select code, name, year, total_count  from StudentCompPass where code in (select code from StudentCompTotDummy2) and term = 'S1') p
on t.code = p.code and t.name = p.name and t.year = p.year) PS1 
full outer join 
(select t.code, t.name, t.year, CAST( CAST (coalesce(p.total_count,0) AS DECIMAL(4,2))/CAST (t.total_count AS DECIMAL(4,2)) AS DECIMAL(4,2)) as pass_s2 from
(select code, name, year, total_count  from StudentCompTot where code in (select code from StudentCompTotDummy2) and term = 'S2') t
left join
(select code, name, year, total_count  from StudentCompPass where code in (select code from StudentCompTotDummy2) and term = 'S2') p
on t.code = p.code and t.name = p.name and t.year = p.year) PS2
on ps1.code = ps2.code and ps1.name = ps2.name and ps1.year = ps2.year
;
