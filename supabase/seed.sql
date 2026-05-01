-- ============================================================================
-- Meal Prep Planner — seed.sql
-- Дефолтные рецепты (14 шт) и гарниры (10 шт) с КБЖУ.
-- Запускать ПОСЛЕ schema.sql в Supabase SQL Editor.
-- Идемпотентность: перед вставкой удаляются существующие is_default=true строки.
-- ============================================================================

-- Очищаем старые дефолты, чтобы можно было перезапускать сидер
delete from public.recipes where is_default = true;
delete from public.sides   where is_default = true;

-- ─────────────────────────────────────────────────────────────────────────────
-- SIDES — гарниры со средними значениями КБЖУ для стандартной порции
-- (значения приблизительные, годятся для оценочного расчёта)
-- ─────────────────────────────────────────────────────────────────────────────
insert into public.sides (user_id, name, emoji, portion, nutrition, is_default) values
  (null, 'Рис',     '🍚', 150, '{"kcal":195,"protein":4,"fat":0.4,"carbs":43}'::jsonb, true),
  (null, 'Паста',   '🍝', 150, '{"kcal":210,"protein":7,"fat":1.2,"carbs":42}'::jsonb, true),
  (null, 'Пюре',    '🥔', 200, '{"kcal":180,"protein":4,"fat":6,"carbs":28}'::jsonb,   true),
  (null, 'Овощи',   '🥦', 200, '{"kcal":70,"protein":3,"fat":0.5,"carbs":14}'::jsonb,  true),
  (null, 'Салат',   '🥗', 150, '{"kcal":30,"protein":1.5,"fat":0.3,"carbs":6}'::jsonb, true),
  (null, 'Лаваш',   '🫓', 80,  '{"kcal":220,"protein":7,"fat":1,"carbs":48}'::jsonb,   true),
  (null, 'Гречка',  '🌾', 150, '{"kcal":165,"protein":6,"fat":1.5,"carbs":33}'::jsonb, true),
  (null, 'Булгур',  '🌾', 150, '{"kcal":125,"protein":5,"fat":0.3,"carbs":27}'::jsonb, true),
  (null, 'Лапша',   '🍜', 150, '{"kcal":210,"protein":7,"fat":1,"carbs":42}'::jsonb,   true),
  (null, 'Хлеб',    '🍞', 60,  '{"kcal":155,"protein":5,"fat":1.5,"carbs":30}'::jsonb, true);

-- ─────────────────────────────────────────────────────────────────────────────
-- RECIPES — 14 заготовок из DEFAULT_RECIPES
-- nutrition пока null (заполнится в Этапе 6 при необходимости)
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Курица BBQ
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Курица BBQ', 'chicken', 'marinade', '🔥',
  $$Бёдра/филе + соус BBQ (80 мл) + 2 зубч. чеснока + копчёная паприка (1 ч.л). Перемешать, в плоский пакет.$$,
  $$Сковорода 15 мин. Подавать с рисом и огурцами.$$,
  20,
  '{"type":"chicken_thigh","grams":250}'::jsonb,
  $$[{"name":"Соус BBQ","amount":"80 мл"},{"name":"Чеснок","amount":"2 зубч."},{"name":"Копчёная паприка","amount":"1 ч.л"}]$$::jsonb,
  true
);

-- 2. Курица Карри
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Курица Карри', 'chicken', 'marinade', '🍛',
  $$Филе + йогурт (150 г) + карри (1 ст.л) + 2 зубч. чеснока. В плоский пакет.$$,
  $$Сковорода 15 мин. Подавать с рисом и йогуртом.$$,
  20,
  '{"type":"chicken_fillet","grams":250}'::jsonb,
  $$[{"name":"Греческий йогурт","amount":"150 г"},{"name":"Карри","amount":"1 ст.л"},{"name":"Чеснок","amount":"2 зубч."}]$$::jsonb,
  true
);

-- 3. Курица Азия
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Курица Азия', 'chicken', 'marinade', '🥢',
  $$Филе + соевый соус (30 мл) + мёд (1 ст.л) + имбирь тёртый (1 ч.л) + 2 зубч. чеснока + кунжут. В пакет.$$,
  $$Сковорода 12 мин. С рисом/лапшой, посыпать кунжутом.$$,
  15,
  '{"type":"chicken_fillet","grams":250}'::jsonb,
  $$[{"name":"Соевый соус","amount":"30 мл"},{"name":"Мёд","amount":"1 ст.л"},{"name":"Имбирь","amount":"1 ч.л тёртый"},{"name":"Чеснок","amount":"2 зубч."},{"name":"Кунжут","amount":"1 ст.л"}]$$::jsonb,
  true
);

-- 4. Курица Кефирная
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Курица Кефирная', 'chicken', 'marinade', '🥛',
  $$Филе + кефир (200 мл) + кинза (пучок) + 2-3 зубч. чеснока + яблочный уксус (20 мл). В пакет.$$,
  $$Сковорода 15 мин. С овощами и лавашом.$$,
  15,
  '{"type":"chicken_fillet","grams":250}'::jsonb,
  $$[{"name":"Кефир","amount":"200 мл"},{"name":"Кинза","amount":"1 пучок"},{"name":"Чеснок","amount":"2-3 зубч."},{"name":"Яблочный уксус","amount":"20 мл"}]$$::jsonb,
  true
);

-- 5. Котлеты с кукурузой
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Котлеты с кукурузой', 'chicken', 'semi', '🌽',
  $$Мелко порубить 300 г филе. + ½ банки кукурузы + 75 г сыра тёрт. + 1 яйцо + 1.5 ст.л сметаны + 1 ст.л муки + соль/перец. Сформовать котлеты, на пергамент → морозилка.$$,
  $$Жарить на среднем огне по 5 мин/сторону. С пюре и салатом.$$,
  20,
  '{"type":"chicken_fillet","grams":300}'::jsonb,
  $$[{"name":"Кукуруза консерв.","amount":"½ банки"},{"name":"Сыр твёрдый","amount":"75 г"},{"name":"Яйцо","amount":"1 шт"},{"name":"Сметана","amount":"1.5 ст.л"},{"name":"Мука","amount":"1 ст.л"}]$$::jsonb,
  true
);

-- 6. Котлеты с грибами
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Котлеты с грибами', 'chicken', 'semi', '🍄',
  $$Порубить 300 г филе. Обжарить 200 г шампиньонов + 1 лук. + 1 яйцо + 1.5 ст.л сметаны + 1 ст.л муки + соль. Сформовать → морозилка.$$,
  $$Жарить под крышкой 12 мин. С пастой и сметаной.$$,
  20,
  '{"type":"chicken_fillet","grams":300}'::jsonb,
  $$[{"name":"Шампиньоны","amount":"200 г"},{"name":"Лук","amount":"1 шт"},{"name":"Яйцо","amount":"1 шт"},{"name":"Сметана","amount":"1.5 ст.л"},{"name":"Мука","amount":"1 ст.л"}]$$::jsonb,
  true
);

-- 7. Шашлычки с беконом
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Шашлычки с беконом', 'chicken', 'semi', '🍢',
  $$Нарезать 300 г филе кубиками. Бекон (150 г) — полосками. Нанизать чередуя на шпажки. Посолить, поперчить → в пакет → морозилка.$$,
  $$Сковорода-гриль или духовка 200° — 12-15 мин. С лавашом и соусом.$$,
  15,
  '{"type":"chicken_fillet","grams":300}'::jsonb,
  $$[{"name":"Бекон","amount":"150 г"},{"name":"Шпажки","amount":"8-10 шт"}]$$::jsonb,
  true
);

-- 8. Фрикадельки куриные
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Фрикадельки куриные', 'chicken', 'semi', '🧆',
  $$350 г фарша + 1 яйцо + 2 зубч. чеснока + зелень (укроп/петрушка) + соль/перец. Скатать шарики → на доску → морозилка 2 ч → ссыпать в пакет.$$,
  $$Суп: вода → картошка → через 10 мин фрикадельки (20 мин). Паста: в томатный соус 12 мин.$$,
  20,
  '{"type":"chicken_mince","grams":350}'::jsonb,
  $$[{"name":"Яйцо","amount":"1 шт"},{"name":"Чеснок","amount":"2 зубч."},{"name":"Зелень (укроп/петрушка)","amount":"1 пучок"}]$$::jsonb,
  true
);

-- 9. Свинина под сыром
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Свинина под сыром', 'pork', 'marinade', '🧀',
  $$300 г свинины пластами + кетчуп (100 мл) + соль/перец. Мариновать. Соус: сметана + горчица + чеснок. Покрыть мясо соусом + сыр сверху → в пакет → морозилка.$$,
  $$Из морозилки в духовку 180° — 25-30 мин. С рисом или пюре.$$,
  30,
  '{"type":"pork","grams":300}'::jsonb,
  $$[{"name":"Кетчуп","amount":"100 мл"},{"name":"Сметана","amount":"2 ст.л"},{"name":"Горчица","amount":"1 ст.л"},{"name":"Сыр твёрдый","amount":"75 г"},{"name":"Чеснок","amount":"2 зубч."}]$$::jsonb,
  true
);

-- 10. Свинина томат-мёд
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Свинина томат-мёд', 'pork', 'marinade', '🍯',
  $$300 г свинины крупными кусками + протёртые томаты (150 г) + горчица (1 ст.л) + мёд (1 ст.л) + 2 зубч. чеснока + соль/перец. В пакет → морозилка.$$,
  $$Сковорода 15-18 мин на среднем огне. С рисом/булгуром и зеленью.$$,
  20,
  '{"type":"pork","grams":300}'::jsonb,
  $$[{"name":"Протёртые томаты","amount":"150 г"},{"name":"Горчица","amount":"1 ст.л"},{"name":"Мёд","amount":"1 ст.л"},{"name":"Чеснок","amount":"2 зубч."}]$$::jsonb,
  true
);

-- 11. Отбивные в панировке
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Отбивные в панировке', 'pork', 'semi', '🍖',
  $$350 г свинины нарезать пластами 1 см, отбить. Посолить, поперчить. Обмакнуть в яйцо → панировочные сухари → на пергамент → морозилка.$$,
  $$Жарить в масле по 4-5 мин/сторону. С пюре и салатом.$$,
  15,
  '{"type":"pork","grams":350}'::jsonb,
  $$[{"name":"Яйцо","amount":"1 шт"},{"name":"Панировочные сухари","amount":"50 г"}]$$::jsonb,
  true
);

-- 12. Рулетики с грибами
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Рулетики с грибами', 'pork', 'semi', '🌀',
  $$350 г свинины отбить тонко. На каждый кусок — обжаренные шампиньоны (100 г) + лук + тёртый сыр (50 г). Свернуть рулетом → в контейнер → морозилка.$$,
  $$Духовка 200° ~20 мин. С рисом/картошкой и сметаной.$$,
  25,
  '{"type":"pork","grams":350}'::jsonb,
  $$[{"name":"Шампиньоны","amount":"100 г"},{"name":"Лук","amount":"1 шт"},{"name":"Сыр твёрдый","amount":"50 г"}]$$::jsonb,
  true
);

-- 13. Гнёзда «Бургер»
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Гнёзда «Бургер»', 'pork', 'semi', '🍔',
  $$300 г свиного фарша — сформовать гнёзда (углубление в центре). Начинка: ломтик сыра + марин. огурцы + томат + красный лук. Соус: сметана + BBQ/кетчуп → в контейнер → морозилка.$$,
  $$Духовка 180° ~15 мин. Собрать в булке или лаваше.$$,
  20,
  '{"type":"pork_mince","grams":300}'::jsonb,
  $$[{"name":"Сыр твёрдый","amount":"50 г"},{"name":"Маринованные огурцы","amount":"3-4 шт"},{"name":"Томаты","amount":"1 шт"},{"name":"Красный лук","amount":"1 шт"},{"name":"Сметана/кетчуп","amount":"по 1 ст.л"}]$$::jsonb,
  true
);

-- 14. Свинина с овощами
insert into public.recipes (user_id, name, type, category, emoji, recipe, serve, time, meat, ingredients, is_default) values (
  null, 'Свинина с овощами', 'pork', 'semi', '🫕',
  $$350 г свинины кусками + 3 картошки кубиками + 2 моркови + 1 лук. Соль, перец, паприка. Всё в пакет для запекания → морозилка.$$,
  $$Пакет в холодную духовку → 180° до готовности (~40 мин). С хлебом и салатом.$$,
  40,
  '{"type":"pork","grams":350}'::jsonb,
  $$[{"name":"Картофель","amount":"3 шт"},{"name":"Морковь","amount":"2 шт"},{"name":"Лук","amount":"1 шт"},{"name":"Пакет для запекания","amount":"1 шт"}]$$::jsonb,
  true
);

-- ─────────────────────────────────────────────────────────────────────────────
-- Проверка: должно быть 14 рецептов и 10 гарниров с is_default=true
-- ─────────────────────────────────────────────────────────────────────────────
do $$
declare
  rcount int;
  scount int;
begin
  select count(*) into rcount from public.recipes where is_default = true;
  select count(*) into scount from public.sides   where is_default = true;
  raise notice 'Default recipes inserted: %', rcount;
  raise notice 'Default sides inserted: %', scount;
end $$;
