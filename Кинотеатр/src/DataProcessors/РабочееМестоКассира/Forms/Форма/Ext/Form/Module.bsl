&НаКлиенте
Процедура НазадВМеню(Команда)
	ЭтаФорма.Закрыть();
КонецПроцедуры

&НаКлиенте
Процедура КупитьПопкорн(Команда)
	ДобавитьТоварВЧек("Попкорн соленый большой");
КонецПроцедуры

&НаКлиенте
Процедура КупитьНапиток(Команда)
	ДобавитьТоварВЧек("Напиток 0,5 л");
КонецПроцедуры

&НаКлиенте
Процедура ОчиститьЧек(Команда)
	Чек.Очистить();
	ИтоговаяСумма = 0;
КонецПроцедуры

&НаКлиенте
Процедура ОплатаКартой(Команда)
	ОформитьПродажу("Банковская карта");
КонецПроцедуры

&НаКлиенте
Процедура ОплатаНаличными(Команда)
	ОформитьПродажу("Наличные");
КонецПроцедуры

&НаКлиенте
Процедура ДобавитьТоварВЧек(ИмяТовара)
	СсылкаНаТовар = НайтиТоварНаСервере(ИмяТовара);
	ЦенаТовара = ЦенаТовараНаСервереКассы(ИмяТовара);
	Если ЦенаТовара <= 0 Тогда
		ПоказатьОповещениеПользователя("Нет цены", , "Установите цену товара в регистре Цены.");
		Возврат;
	КонецЕсли;
	НайденныеСтроки = Чек.НайтиСтроки(Новый Структура("Номенклатура", СсылкаНаТовар));
	
	Если НайденныеСтроки.Количество() > 0 Тогда
		СтрокаЧек = НайденныеСтроки[0];
		СтрокаЧек.Количество = СтрокаЧек.Количество + 1;
		СтрокаЧек.Сумма = СтрокаЧек.Количество * СтрокаЧек.Цена;
	Иначе
		СтрокаЧек = Чек.Добавить();
		СтрокаЧек.Номенклатура = СсылкаНаТовар;
		СтрокаЧек.Цена = ЦенаТовара;
		СтрокаЧек.Количество = 1;
		СтрокаЧек.Сумма = ЦенаТовара;
	КонецЕсли;
	
	ИтоговаяСумма = Чек.Итог("Сумма");
КонецПроцедуры

&НаСервереБезКонтекста
Функция НайтиТоварНаСервере(ИмяТовара)
	Возврат Справочники.Номенклатура.НайтиПоНаименованию(ИмяТовара);
КонецФункции

&НаСервереБезКонтекста
Функция ЦенаТовараНаСервереКассы(ИмяТовара)
	СсылкаНаТовар = Справочники.Номенклатура.НайтиПоНаименованию(ИмяТовара);
	Если НЕ ЗначениеЗаполнено(СсылкаНаТовар) Тогда Возврат 0; КонецЕсли;
	Возврат КинотеатрСервер.ЦенаНаДату(СсылкаНаТовар, ТекущаяДата());
КонецФункции

&НаКлиенте
Процедура ОформитьПродажу(ТипОплаты)

    Если Чек.Количество() = 0 Тогда
        ПоказатьОповещениеПользователя("Внимание", , "Чек пуст! Добавьте товары.");
        Возврат;
    КонецЕсли;

    ОтветСервера = СоздатьДокументПродажиНаСервере(ТипОплаты);

    Если НЕ ОтветСервера.Успех Тогда
        ПоказатьОповещениеПользователя("Ошибка продажи", , ОтветСервера.Текст);
        Возврат;
    КонецЕсли;

    Чек.Очистить();
    ИтоговаяСумма = 0;
    ПоказатьОповещениеПользователя("Успешно!", , ОтветСервера.Текст);

КонецПроцедуры

&НаСервере
Функция СоздатьДокументПродажиНаСервере(ТипОплаты)

    Результат = Новый Структура("Успех,Текст", Ложь, "");

    Попытка
        Док = Документы.Расход.СоздатьДокумент();
        Док.Дата = ТекущаяДата();
        Док.Организация = Справочники.Организации.НайтиПоНаименованию("Кинотеатр Премьера");
        Если НЕ ЗначениеЗаполнено(Док.Организация) Тогда
            ВызватьИсключение "Не найдена организация «Кинотеатр Премьера». Заполните справочник организаций.";
        КонецЕсли;

        // Записываем выбранный кассиром способ оплаты в реквизит документа Расход.
        Док.СпособОплаты = ТипОплаты;

        ИмяТЧ = "Товары";
        Попытка
            Тест = Док[ИмяТЧ];
        Исключение
            Попытка
                ИмяТЧ = "Номенклатура";
                Тест = Док[ИмяТЧ];
            Исключение
                ИмяТЧ = "Состав";
            КонецПопытки;
        КонецПопытки;

        Для Каждого Стр Из Чек Цикл
            НоваяСтр = Док[ИмяТЧ].Добавить();
            НоваяСтр.Номенклатура = Стр.Номенклатура;
            НоваяСтр.Количество = Стр.Количество;
            НоваяСтр.Цена = Стр.Цена;
            НоваяСтр.Сумма = Стр.Сумма;
        КонецЦикла;

        Док.Записать(РежимЗаписиДокумента.Проведение);

        Если НЕ Док.Проведен Тогда
            Результат.Текст = "Документ Расход не проведен. Проверьте сообщения 1С.";
            Возврат Результат;
        КонецЕсли;

        Результат.Успех = Истина;
        Результат.Текст = "Продажа оформлена. Документ: " + Строка(Док.Ссылка)
            + ". Способ оплаты: " + ТипОплаты + ".";

    Исключение
        Результат.Текст = "Не удалось оформить продажу: " + ОписаниеОшибки();
    КонецПопытки;

    Возврат Результат;

КонецФункции

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
    РежимИзПараметров = Неопределено;
    Если Параметры.Свойство("РежимКассы", РежимИзПараметров)
        И (РежимИзПараметров = "bar" Или РежимИзПараметров = "tickets") Тогда
        РежимКассы = РежимИзПараметров;
    ИначеЕсли НЕ ЗначениеЗаполнено(РежимКассы) Тогда
        РежимКассы = "tickets";
    КонецЕсли;
    ОбновитьЭкранКинотеатраНаСервере();
КонецПроцедуры

// Перехватывает клики по кнопкам "Забронировать", "Оплатить" и "Отменить бронь" из HTML
&НаКлиенте
Процедура ПолеHTMLПриНажатии(Элемент, ДанныеСобытия, СтандартнаяОбработка)
    
    // Проверяем, кликнул ли кассир по ссылке-команде 1С
    Href = "";
    Попытка
        Href = ДанныеСобытия.Href;
    Исключение
        Возврат;
    КонецПопытки;
    
    Если СтрНачинаетсяС(Href, "http://1c.action/") Тогда
        СтандартнаяОбработка = Ложь; // Блокируем переход браузера
        КомандаСтрока = СтрЗаменить(Href, "http://1c.action/", "");
        
        Если КомандаСтрока = "MODE|BAR" Тогда
            РежимКассы = "bar";
            ОбновитьЭкранКинотеатраНаСервере();
            Возврат;
        ИначеЕсли КомандаСтрока = "MODE|TICKETS" Тогда
            РежимКассы = "tickets";
            ОбновитьЭкранКинотеатраНаСервере();
            Возврат;
        КонецЕсли;

        Если СтрНачинаетсяС(КомандаСтрока, "TICKET~") Тогда
            ОтветСервера = ОформитьБилетКассыНаСервере(КомандаСтрока);
            Если ЗначениеЗаполнено(ОтветСервера) Тогда
                ПоказатьОповещениеПользователя("Кинотеатр Премьера", , ОтветСервера);
            КонецЕсли;
            Возврат;
        КонецЕсли;
        Если СтрНачинаетсяС(КомандаСтрока, "REDEEM~") Тогда
            ОтветСервера = ПродатьБроньБилетаКассыНаСервере(КомандаСтрока);
            ПоказатьОповещениеПользователя("Билет по брони", , ОтветСервера);
            ОбновитьЭкранКинотеатраНаСервере();
            Возврат;
        КонецЕсли;
        ОтветСервера = ВыполнитьКомандуКинотеатраНаСервере(КомандаСтрока);
        Если ЗначениеЗаполнено(ОтветСервера) Тогда
            ПоказатьОповещениеПользователя("Кинотеатр Премьера", , ОтветСервера);
        КонецЕсли;
    КонецЕсли;
    
КонецПроцедуры

// Выполняет реальные проводки в регистрах 1С (ОстаткиТоваров, РезервыТоваров, Продажи)
&НаСервере
Функция ВыполнитьКомандуКинотеатраНаСервере(КомандаСтрока)
    
    // Формат команды: ТИП|ПопкорнШт|НапитокШт|СуммаБилетов|СпособОплаты
    Части = СтрРазделить(КомандаСтрока, "|", Ложь);
    Если Части.Количество() < 4 Тогда Возврат ""; КонецЕсли;

    ТипДействия  = Части[0]; // BOOK (бронь), BUY (продажа), CANCEL (отмена брони)
    КолПопкорн   = Число(Части[1]);
    КолНапиток   = Число(Части[2]);
    СуммаБилетов = Число(Части[3]);
    СпособОплатыКинобара = "";
    Если Части.Количество() >= 5 Тогда
        Если Части[4] = "CASH" Тогда
            СпособОплатыКинобара = "Наличные";
        ИначеЕсли Части[4] = "CARD" Тогда
            СпособОплатыКинобара = "Банковская карта";
        КонецЕсли;
    КонецЕсли;

    // Находим основную организацию и покупателя
    Орг = Справочники.Организации.НайтиПоНаименованию("Кинотеатр Премьера");
    Если Орг.Пустая() Тогда
        ВыборкаОрг = Справочники.Организации.Выбрать();
        Если ВыборкаОрг.Следующий() Тогда Орг = ВыборкаОрг.Ссылка; КонецЕсли;
    КонецЕсли;
    
    Покуп = Справочники.Покупатели.НайтиПоНаименованию("Розничный покупатель");
    Если Покуп.Пустая() Тогда
        ВыборкаПок = Справочники.Покупатели.Выбрать();
        Если ВыборкаПок.Следующий() Тогда Покуп = ВыборкаПок.Ссылка; КонецЕсли;
    КонецЕсли;
    
    НомПопкорн = Справочники.Номенклатура.НайтиПоНаименованию("Попкорн соленый большой");
    НомНапиток = Справочники.Номенклатура.НайтиПоНаименованию("Напиток 0,5 л");
    
    ТекстОтвета = "";
    
    Попытка
        Если ТипДействия = "BOOK" Тогда
            // СОЗДАЕМ И ПРОВОДИМ РЕАЛЬНЫЙ ДОКУМЕНТ "БРОНИРОВАНИЕ"
            Док = Документы.Бронирование.СоздатьДокумент();
            Док.Дата = ТекущаяДата();
			Док.СрокБрони = Док.Дата + 15 * 60;
            Док.Организация = Орг;
            Док.Покупатель = Покуп;
            Док.Статус = "Забронировано";
            
            Если КолПопкорн > 0 И ЗначениеЗаполнено(НомПопкорн) Тогда
                ЦенаПопкорна = КинотеатрСервер.ЦенаНаДату(НомПопкорн, ТекущаяДата());
                Если ЦенаПопкорна <= 0 Тогда ВызватьИсключение "Не задана цена попкорна в регистре Цены."; КонецЕсли;
                Стр = Док.Товары.Добавить();
                Стр.Номенклатура = НомПопкорн;
                Стр.Количество = КолПопкорн;
                Стр.Цена = ЦенаПопкорна;
                Стр.Сумма = КолПопкорн * ЦенаПопкорна;
            КонецЕсли;
            
            Если КолНапиток > 0 И ЗначениеЗаполнено(НомНапиток) Тогда
                ЦенаНапитка = КинотеатрСервер.ЦенаНаДату(НомНапиток, ТекущаяДата());
                Если ЦенаНапитка <= 0 Тогда ВызватьИсключение "Не задана цена напитка в регистре Цены."; КонецЕсли;
                Стр = Док.Товары.Добавить();
                Стр.Номенклатура = НомНапиток;
                Стр.Количество = КолНапиток;
                Стр.Цена = ЦенаНапитка;
                Стр.Сумма = КолНапиток * ЦенаНапитка;
            КонецЕсли;
            
            Док.СуммаДокумента = Док.Товары.Итог("Сумма") + СуммаБилетов;
            Док.Записать(РежимЗаписиДокумента.Проведение);
            ТекстОтвета = "✅ Проведен документ Бронирование № " + Док.Номер + " (Товар переведен в РезервыТоваров!)";
            
        ИначеЕсли ТипДействия = "BUY" Тогда
            // СОЗДАЕМ И ПРОВОДИМ РЕАЛЬНЫЙ ДОКУМЕНТ "РАСХОД" (ПРОДАЖА)
            Док = Документы.Расход.СоздатьДокумент();
            Док.Дата = ТекущаяДата();
            Док.Организация = Орг;
            Док.Покупатель = Покуп;
            Если ЗначениеЗаполнено(СпособОплатыКинобара) Тогда
                Док.СпособОплаты = СпособОплатыКинобара;
            КонецЕсли;
            
            Если КолПопкорн > 0 И ЗначениеЗаполнено(НомПопкорн) Тогда
                ЦенаПопкорна = КинотеатрСервер.ЦенаНаДату(НомПопкорн, ТекущаяДата());
                Если ЦенаПопкорна <= 0 Тогда ВызватьИсключение "Не задана цена попкорна в регистре Цены."; КонецЕсли;
                Стр = Док.Товары.Добавить();
                Стр.Номенклатура = НомПопкорн;
                Стр.Количество = КолПопкорн;
                Стр.Цена = ЦенаПопкорна;
                Стр.Сумма = КолПопкорн * ЦенаПопкорна;
            КонецЕсли;
            
            Если КолНапиток > 0 И ЗначениеЗаполнено(НомНапиток) Тогда
                ЦенаНапитка = КинотеатрСервер.ЦенаНаДату(НомНапиток, ТекущаяДата());
                Если ЦенаНапитка <= 0 Тогда ВызватьИсключение "Не задана цена напитка в регистре Цены."; КонецЕсли;
                Стр = Док.Товары.Добавить();
                Стр.Номенклатура = НомНапиток;
                Стр.Количество = КолНапиток;
                Стр.Цена = ЦенаНапитка;
                Стр.Сумма = КолНапиток * ЦенаНапитка;
            КонецЕсли;
            
            Если Док.Товары.Количество() > 0 Тогда
                Док.Записать(РежимЗаписиДокумента.Проведение);
                ТекстОтвета = "Проведен чек Расход № " + Док.Номер
                    + ". Способ оплаты: " + СпособОплатыКинобара
                    + ". Товары списаны со склада.";
            Иначе
                ТекстОтвета = "Продажа не оформлена: билеты пока не заведены в учет 1С";
            КонецЕсли;
            
        ИначеЕсли ТипДействия = "CANCEL" Тогда
            // ОТМЕНЯЕМ ПОСЛЕДНЮЮ АКТИВНУЮ БРОНЬ В БАЗЕ 1С
            ЗапросБрони = Новый Запрос;
            ЗапросБрони.Текст = 
            "ВЫБРАТЬ ПЕРВЫЕ 1
            |   Бронирование.Ссылка КАК Ссылка
            |ИЗ
            |   Документ.Бронирование КАК Бронирование
            |ГДЕ
            |   Бронирование.Проведен = Истина
            |   И Бронирование.Статус = &Статус
            |   И Бронирование.Ссылка НЕ В (ВЫБРАТЬ Продажа.ДокументОснование ИЗ Документ.Расход КАК Продажа
            |       ГДЕ Продажа.Проведен)
            |УПОРЯДОЧИТЬ ПО
            |   Бронирование.Дата УБЫВ";
            ЗапросБрони.УстановитьПараметр("Статус", "Забронировано");
            Выб = ЗапросБрони.Выполнить().Выбрать();
            Если Выб.Следующий() Тогда
                ОбъектБрони = Выб.Ссылка.ПолучитьОбъект();
                ОбъектБрони.Записать(РежимЗаписиДокумента.ОтменаПроведения);
                ОбъектБрони.Статус = "Отменено";
                ОбъектБрони.Записать(РежимЗаписиДокумента.Запись);
                ТекстОтвета = " Бронь № " + ОбъектБрони.Номер + " отменена! Товары возвращены в свободные остатки!";
            Иначе
                ТекстОтвета = "Активных броней кинобара для отмены нет";
            КонецЕсли;
        КонецЕсли;
    Исключение
        ТекстОтвета = "⚠️ " + ОписаниеОшибки();
    КонецПопытки;
    
    // Обновляем остатки на экране
    ОбновитьЭкранКинотеатраНаСервере();
    Возврат ТекстОтвета;
    
КонецФункции

// Подтягивает реальные свободные остатки и резервы из регистров 1С и рисует HTML-интерфейс
&НаСервере
Процедура ОбновитьЭкранКинотеатраНаСервере()
    
    СвободноПопкорн = 0; РезервПопкорн = 0;
    СвободноНапиток = 0; РезервНапиток = 0;
    
    Запрос = Новый Запрос;
    Запрос.Текст = 
    "ВЫБРАТЬ
    |   Ном.Наименование КАК Наименование,
    |   ЕСТЬNULL(Склад.КоличествоОстаток, 0) КАК НаСкладе,
    |   ЕСТЬNULL(Резерв.КоличествоОстаток, 0) КАК ВРезерве,
    |   ЕСТЬNULL(Склад.КоличествоОстаток, 0) - ЕСТЬNULL(Резерв.КоличествоОстаток, 0) КАК Свободно
    |ИЗ
    |   Справочник.Номенклатура КАК Ном
    |   ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.ОстаткиТоваров.Остатки(, Организация = &Организация) КАК Склад
    |       ПО Ном.Ссылка = Склад.Номенклатура
    |   ЛЕВОЕ СОЕДИНЕНИЕ РегистрНакопления.РезервыТоваров.Остатки(, Организация = &Организация) КАК Резерв
    |       ПО Ном.Ссылка = Резерв.Номенклатура";
    
    Запрос.УстановитьПараметр("Организация", Справочники.Организации.НайтиПоНаименованию("Кинотеатр Премьера"));
    Выборка = Запрос.Выполнить().Выбрать();
    Пока Выборка.Следующий() Цикл
        Имя = ВРег(Выборка.Наименование);
        Если СтрНайти(Имя, "ПОПКОРН") > 0 Тогда
            СвободноПопкорн = СвободноПопкорн + Выборка.Свободно;
            РезервПопкорн   = РезервПопкорн + Выборка.ВРезерве;
        ИначеЕсли СтрНайти(Имя, "НАПИТОК") > 0 Тогда
            СвободноНапиток = СвободноНапиток + Выборка.Свободно;
            РезервНапиток   = РезервНапиток + Выборка.ВРезерве;
        КонецЕсли;
    КонецЦикла;
    
    ПолеHTML = ПолучитьHTMLШаблонКинотеатра(СвободноПопкорн, РезервПопкорн, СвободноНапиток, РезервНапиток, РежимКассы);
    
КонецПроцедуры


// Возвращает фотографию товара из реквизита Фото (ХранилищеЗначения)
// в формате Base64 для отображения внутри HTML кассы.
&НаСервереБезКонтекста
Функция ПолучитьФотоТовараBase64Кассы(ИмяТовара)
    СсылкаНаТовар = Справочники.Номенклатура.НайтиПоНаименованию(ИмяТовара);
    Если НЕ ЗначениеЗаполнено(СсылкаНаТовар) Тогда
        Возврат "";
    КонецЕсли;

    ОбъектТовара = СсылкаНаТовар.ПолучитьОбъект();
    Если НЕ ЗначениеЗаполнено(ОбъектТовара.Фото) Тогда
        Возврат "";
    КонецЕсли;

    ДанныеФото = ОбъектТовара.Фото.Получить();
    Если ДанныеФото = Неопределено Тогда
        Возврат "";
    КонецЕсли;

    Возврат Base64Строка(ДанныеФото);
КонецФункции


// ЭТАП 1: динамические сеансы и схема мест (без записи билетов)
&НаСервере
Функция ПолучитьHTMLШаблонКинотеатра(СвобПоп, РезПоп, СвобНап, РезНап, РежимОтображения)
    // Получаем фотографии непосредственно из справочника Номенклатура.
    ФотоПопкорна = ПолучитьФотоТовараBase64Кассы("Попкорн соленый большой");
    ФотоНапитка = ПолучитьФотоТовараBase64Кассы("Напиток 0,5 л");

    Если ЗначениеЗаполнено(ФотоПопкорна) Тогда
        HTMLФотоПопкорна = "<img src=""data:image/png;base64," + ФотоПопкорна + """ alt=""Попкорн"">";
    Иначе
        HTMLФотоПопкорна = "";
    КонецЕсли;

    Если ЗначениеЗаполнено(ФотоНапитка) Тогда
        HTMLФотоНапитка = "<img src=""data:image/png;base64," + ФотоНапитка + """ alt=""Напиток"">";
    Иначе
        HTMLФотоНапитка = "";
    КонецЕсли;

    ЦенаПопкорна = КинотеатрСервер.ЦенаНаДату(Справочники.Номенклатура.НайтиПоНаименованию("Попкорн соленый большой"), ТекущаяДата());
    ЦенаНапитка = КинотеатрСервер.ЦенаНаДату(Справочники.Номенклатура.НайтиПоНаименованию("Напиток 0,5 л"), ТекущаяДата());

    Элементы.КупитьПопкорн.Заголовок = "Попкорн соленый" + Символы.ПС + ?(ЦенаПопкорна > 0, Строка(ЦенаПопкорна) + " ₽", "цена не задана");
    Элементы.КупитьНапиток.Заголовок = "Напиток 0,5 л" + Символы.ПС + ?(ЦенаНапитка > 0, Строка(ЦенаНапитка) + " ₽", "цена не задана");
    Элементы.КупитьПопкорн.Доступность = ЦенаПопкорна > 0;
    Элементы.КупитьНапиток.Доступность = ЦенаНапитка > 0;

    СеансыДанные = Новый Массив;
    ЗапросСеансов = Новый Запрос;
    ЗапросСеансов.Текст =
    "ВЫБРАТЬ
    | Сеансы.Ссылка КАК Сеанс,
    | Сеансы.Фильм.Наименование КАК Фильм,
    | Сеансы.Зал.Наименование КАК Зал,
    | Сеансы.Зал КАК ЗалСсылка,
    | Сеансы.ДатаНачала КАК Начало,
    | Сеансы.ЦенаБилета КАК Цена
    |ИЗ Справочник.Сеансы КАК Сеансы
    |ГДЕ Сеансы.ДатаНачала > &Сейчас
    |УПОРЯДОЧИТЬ ПО Сеансы.ДатаНачала";
    ЗапросСеансов.УстановитьПараметр("Сейчас", ТекущаяДата());
    РезультатСеансов = ЗапросСеансов.Выполнить();
    ВыборкаСеансов = РезультатСеансов.Выбрать();
    Пока ВыборкаСеансов.Следующий() Цикл
        Данные = Новый Структура;
        Данные.Вставить("id", Строка(ВыборкаСеансов.Сеанс.УникальныйИдентификатор()));
        Данные.Вставить("name", ВыборкаСеансов.Фильм);
        Данные.Вставить("info", ВыборкаСеансов.Зал + " · " + Формат(ВыборкаСеансов.Начало, "ДФ=dd.MM.yyyy HH:mm"));
        Данные.Вставить("price", ВыборкаСеансов.Цена);
        МестаДанные = Новый Массив;
        ЗапросМест = Новый Запрос;
        ЗапросМест.Текст =
        "ВЫБРАТЬ
        | Места.Ссылка КАК Место,
        | Места.Ряд КАК Ряд,
        | Места.НомерМеста КАК Номер
        |ИЗ Справочник.Места КАК Места
        |ГДЕ Места.Зал = &Зал
        |УПОРЯДОЧИТЬ ПО Места.Ряд, Места.НомерМеста";
        ЗапросМест.УстановитьПараметр("Зал", ВыборкаСеансов.ЗалСсылка);
        ВыборкаМест = ЗапросМест.Выполнить().Выбрать();
        Пока ВыборкаМест.Следующий() Цикл
            Статус = СтатусМестаКассы(ВыборкаСеансов.Сеанс, ВыборкаМест.Место);
            ИДБрони = "";
            Если Статус = "booked" Тогда
                СсылкаБрониКассы = АктивнаяБроньБилетаКассы(ВыборкаСеансов.Сеанс, ВыборкаМест.Место);
                Если ЗначениеЗаполнено(СсылкаБрониКассы) Тогда
                    ИДБрони = Строка(СсылкаБрониКассы.УникальныйИдентификатор());
                Иначе
                    Статус = "free";
                КонецЕсли;
            КонецЕсли;
            МестаДанные.Добавить(Новый Структура("row,number,status,id,booking", ВыборкаМест.Ряд, ВыборкаМест.Номер, Статус, Строка(ВыборкаМест.Место.УникальныйИдентификатор()), ИДБрони));
        КонецЦикла;
        Данные.Вставить("seats", МестаДанные);
        СеансыДанные.Добавить(Данные);
    КонецЦикла;
    HTML = "<!DOCTYPE html>
    |<html lang=""ru""><head><meta charset=""utf-8""><style>
    |*{box-sizing:border-box}
    |:root{color-scheme:dark}
    |body{margin:0;min-height:100vh;background:radial-gradient(ellipse at 50% -20%,#29202d 0%,#14141c 48%,#101117 100%);color:#f4f2f6;font:14px 'Segoe UI',Arial,sans-serif;padding:24px}
    |h1{font-size:26px;line-height:1.2;letter-spacing:-.4px;margin:0 0 7px;font-weight:750}
    |small,.muted{color:#a9a8b8}
    |.top{display:flex;justify-content:space-between;align-items:center;gap:18px;margin-bottom:24px}
    |.top small{font-size:12px;letter-spacing:.15px}
    |.tag{background:#522039;color:#fff;border-radius:7px;padding:9px 14px}
    |.layout{display:grid;grid-template-columns:270px minmax(0,1fr);gap:16px;align-items:stretch}
    |.panel{background:linear-gradient(145deg,#1d1e28 0%,#191a23 100%);border:1px solid #373846;border-radius:15px;padding:20px;box-shadow:0 12px 30px rgba(0,0,0,.14)}
    |.title{font-size:16px;font-weight:700;margin-bottom:16px;color:#f7f4f8}
    |.session{display:block;width:100%;text-align:left;border:1px solid #3b3d4b;background:#242530;color:#f6f3f7;border-radius:10px;padding:13px 14px;margin:0 0 10px;cursor:pointer;transition:border-color .16s,background .16s,transform .16s}
    |.session:hover{border-color:#98506e;background:#2d2530;transform:translateY(-1px)}
    |.session.active{border-color:#d05c88;background:linear-gradient(110deg,#472536,#34212d);box-shadow:inset 3px 0 #d05c88}
    |.session b{display:block;margin-bottom:5px;font-size:13px}
    |.session span{color:#b6b4c2;font-size:12px}
    |.screen{margin:24px auto 30px;max-width:650px;border-top:4px solid #c4517d;border-radius:50% 50% 0 0;text-align:center;padding-top:17px;letter-spacing:6px;color:#e9b4c9;text-shadow:0 0 18px rgba(196,81,125,.18)}
    |.seatrow{display:flex;align-items:center;justify-content:center;gap:9px;margin:11px 0}
    |.rowlabel{width:62px;color:#a9a8b8;text-align:right;margin-right:7px;font-size:12px}
    |.seat{min-width:42px;height:39px;border:1px solid #399b79;background:#193e35;color:#c3f4dc;border-radius:8px;cursor:pointer;transition:transform .14s,box-shadow .14s,background .14s}
    |.seat:not(:disabled):hover{transform:translateY(-2px);box-shadow:0 5px 14px rgba(0,0,0,.25)}
    |.seat:focus-visible,.mode-tab:focus-visible,.actionlink:focus-visible,.qty-control button:focus-visible{outline:2px solid #f0a2c0;outline-offset:2px}
    |.seat.sold{background:#42232e;color:#d58da2;border-color:#684052;cursor:not-allowed;opacity:.82}
    |.seat.booked{background:#594322;color:#ffe0a0;border-color:#96702f;cursor:not-allowed}
    |.seat.selected{background:#b83f70;color:#fff;border-color:#ef8caf;box-shadow:0 0 0 2px rgba(184,63,112,.18)}
    |.legend{display:flex;flex-wrap:wrap;gap:16px;color:#b8b6c4;font-size:12px;margin-top:25px}
    |.dot{display:inline-block;width:10px;height:10px;border-radius:3px;margin-right:6px;vertical-align:-1px}
    |.foot{margin-top:18px;padding:15px 16px;background:#252631;border:1px solid #30313e;border-radius:10px;color:#eceaf1;min-height:48px;display:flex;align-items:center}
    |.btn{border:0;background:#873452;color:#fff;padding:11px 17px;border-radius:8px;margin-top:12px;cursor:pointer}
    |.note{font-size:12px;color:#aaa9b8;margin-top:12px;line-height:1.5}
    |.actionlink{display:inline-flex;align-items:center;justify-content:center;text-decoration:none;color:#fff;background:linear-gradient(135deg,#91395e,#77304e);border:1px solid #a64b70;border-radius:8px;padding:11px 16px;margin:12px 9px 0 0;transition:filter .15s,transform .15s,box-shadow .15s}
    |.actionlink:hover{filter:brightness(1.13);transform:translateY(-1px);box-shadow:0 6px 16px rgba(0,0,0,.2)}
    |.mode-tabs{display:flex;gap:8px;flex-shrink:0}
    |.mode-tab{display:inline-block;text-decoration:none;border:1px solid #594052;background:#242530;color:#dedbe4;padding:10px 18px;border-radius:9px;cursor:pointer;transition:background .15s,border-color .15s}
    |.mode-tab:hover{border-color:#a44d70}
    |.mode-tab.active{background:linear-gradient(135deg,#91395e,#77304e);border-color:#c15a83;color:#fff;box-shadow:0 5px 16px rgba(110,38,70,.2)}
    |.bar-panel{min-height:300px}
    |.bar-heading{display:flex;align-items:center;justify-content:space-between;gap:12px;margin:4px 0 18px}
    |.bar-heading .muted{font-size:13px}
    |.bar-grid{display:grid;grid-template-columns:repeat(2,minmax(220px,1fr));gap:14px;margin-top:18px}
    |.product-card{position:relative;display:flex;align-items:center;gap:17px;min-height:142px;background:linear-gradient(145deg,#292a36,#20212b);border:1px solid #414250;border-radius:14px;padding:19px;transition:border-color .18s,transform .18s,box-shadow .18s;overflow:hidden}
    |.product-card:after{content:'';position:absolute;width:130px;height:130px;right:-48px;top:-55px;border-radius:50%;background:rgba(190,72,119,.07);pointer-events:none}
    |.product-card:hover{border-color:#98506e;transform:translateY(-2px);box-shadow:0 10px 24px rgba(0,0,0,.16)}
    |.product-icon{width:86px;height:86px;flex:0 0 86px;display:flex;align-items:center;justify-content:center;overflow:hidden;border-radius:16px;background:linear-gradient(145deg,#593047,#352432);border:1px solid #75405b;font-size:38px;box-shadow:inset 0 1px rgba(255,255,255,.08)}
    |.product-icon img{display:block;width:100%;height:100%;object-fit:cover;border-radius:15px}
    |.product-info{min-width:0;position:relative;z-index:1}
    |.product-name{font-size:16px;font-weight:700;margin-bottom:7px;color:#faf7fa}
    |.product-price{font-size:13px;color:#c7a9b8}
    |.product-label{display:inline-block;margin-top:8px;padding:4px 8px;border-radius:20px;background:#342632;color:#e6b5ca;font-size:10px;letter-spacing:.5px;text-transform:uppercase}
    |.qty-control{display:flex;align-items:center;gap:12px;margin-top:13px}
    |.qty-control button,.clear-btn{width:34px;height:34px;border:1px solid #9c456b;background:#873452;color:#fff;border-radius:9px;padding:0;cursor:pointer;font-size:17px;transition:filter .15s,transform .15s}
    |.qty-control button:hover,.clear-btn:hover{filter:brightness(1.15);transform:translateY(-1px)}
    |.qty-control strong{min-width:22px;text-align:center;font-size:15px}
    |.cart-box{margin-top:17px;padding:15px 17px;background:#242530;border:1px solid #373846;border-radius:12px}
    |.cart-title{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;font-weight:700}
    |.cart-empty{color:#aaa9b8;font-size:13px;padding:4px 0}
    |.cart-line{display:flex;justify-content:space-between;gap:12px;padding:7px 0;color:#d8d5df;font-size:13px;border-bottom:1px solid #373846}
    |.cart-line:last-child{border-bottom:0}
    |.cart-total{display:flex;justify-content:space-between;align-items:center;margin-top:12px;padding-top:12px;border-top:1px solid #454653;font-weight:700}
    |.cart-total strong{font-size:20px;color:#f0b4cc}
    |.clear-btn{width:auto;height:auto;margin:12px 0 0 8px;padding:9px 14px;background:#343541;border-color:#4a4b58;font-size:13px}
    |@media(max-width:850px){body{padding:16px}.layout{grid-template-columns:1fr}.bar-grid{grid-template-columns:1fr}}
    |@media(max-width:520px){body{padding:12px}.top{align-items:flex-start;flex-direction:column}.mode-tabs{width:100%}.mode-tab{flex:1}.panel{padding:15px}.seatrow{gap:5px}.seat{min-width:32px;height:35px}.rowlabel{width:48px;margin-right:3px}.screen{margin:18px auto 24px}}
    |</style></head><body>
    |<div class=""top""><div><h1>Кинотеатр Премьера — касса</h1></div><div class=""mode-tabs""><a id=""ticketsTab"" class=""mode-tab {{TICKET_ACTIVE}}"" href=""http://1c.action/MODE|TICKETS"">Билеты</a><a id=""barTab"" class=""mode-tab {{BAR_ACTIVE}}"" href=""http://1c.action/MODE|BAR"">Кинобар</a></div></div>
    |<div class=""layout"" id=""ticketMode"" style=""{{TICKET_VISIBILITY}}""><section class=""panel""><div class=""title"">Сеансы</div><div id=""sessions"">{{SESSIONS}}</div></section>
    |<section class=""panel""><div class=""title"" id=""sessionTitle"">Выберите сеанс</div><div class=""muted"" id=""sessionInfo"">Отображаются только реальные места выбранного зала</div><div class=""screen"">ЭКРАН</div><div id=""hall""></div><div class=""legend""><span><i class=""dot"" style=""background:#3e9e7b""></i>Свободно</span><span><i class=""dot"" style=""background:#b43e6a""></i>Выбрано</span><span><i class=""dot"" style=""background:#8e6a2d""></i>Бронь</span><span><i class=""dot"" style=""background:#633444""></i>Продано</span></div><div class=""foot"" id=""selection"">Места не выбраны</div><div id=""actions""></div></section></div>
    |<section class=""panel bar-panel"" id=""barMode"" style=""{{BAR_VISIBILITY}}""><div class=""bar-heading""><div><div class=""title"">Кинобар</div><div class=""muted"">Добавьте товары в заказ — количество и сумма обновятся автоматически</div></div></div><div class=""bar-grid""><div class=""product-card""><div class=""product-icon"">{{PHOTO_POPCORN}}</div><div class=""product-info""><div class=""product-name"">Попкорн солёный большой</div><div class=""product-price"">{{PRICE_POPCORN}} ₽ <span class=""muted"">/ шт.</span></div><span class=""product-label"">Классика кино</span><div class=""qty-control""><button type=""button"" aria-label=""Уменьшить попкорн"" onclick=""changeBarQty('popcorn',-1)"">−</button><strong id=""popcornQty"">0</strong><button type=""button"" aria-label=""Добавить попкорн"" onclick=""changeBarQty('popcorn',1)"">+</button></div></div></div><div class=""product-card""><div class=""product-icon"">{{PHOTO_DRINK}}</div><div class=""product-info""><div class=""product-name"">Напиток 0,5 л</div><div class=""product-price"">{{PRICE_DRINK}} ₽ <span class=""muted"">/ шт.</span></div><span class=""product-label"">Освежающий напиток</span><div class=""qty-control""><button type=""button"" aria-label=""Уменьшить напиток"" onclick=""changeBarQty('drink',-1)"">−</button><strong id=""drinkQty"">0</strong><button type=""button"" aria-label=""Добавить напиток"" onclick=""changeBarQty('drink',1)"">+</button></div></div></div></div><div class=""cart-box""><div class=""cart-title""><span>Ваш заказ</span><span class=""muted"" id=""cartCount"">0 товаров</span></div><div id=""cartLines""><div class=""cart-empty"">Пока ничего не добавлено</div></div><div class=""cart-total""><span>Итого к оплате</span><strong id=""barTotal"">0 ₽</strong></div></div><div id=""barActions""></div></section>
    |<script>
    |var sessions={{DATA}};var current=-1;var selected={};var barPopcorn=0;var barDrink=0;var popcornPrice={{PRICE_POPCORN}};var drinkPrice={{PRICE_DRINK}};
    |function changeBarQty(product,delta){if(product==='popcorn'){barPopcorn=Math.max(0,barPopcorn+delta)}else{barDrink=Math.max(0,barDrink+delta)}updateBar()}
    |function updateBar(){document.getElementById('popcornQty').textContent=barPopcorn;document.getElementById('drinkQty').textContent=barDrink;var total=barPopcorn*popcornPrice+barDrink*drinkPrice;var count=barPopcorn+barDrink;document.getElementById('barTotal').textContent=total+' ₽';document.getElementById('cartCount').textContent=count+' '+(count===1?'товар':(count>=2&&count<=4?'товара':'товаров'));var lines=document.getElementById('cartLines');lines.innerHTML='';if(barPopcorn>0){var p=document.createElement('div');p.className='cart-line';p.innerHTML='<span> Попкорн × '+barPopcorn+'</span><strong>'+(barPopcorn*popcornPrice)+' ₽</strong>';lines.appendChild(p)}if(barDrink>0){var d=document.createElement('div');d.className='cart-line';d.innerHTML='<span> Напиток × '+barDrink+'</span><strong>'+(barDrink*drinkPrice)+' ₽</strong>';lines.appendChild(d)}if(count===0){var empty=document.createElement('div');empty.className='cart-empty';empty.textContent='Пока ничего не добавлено';lines.appendChild(empty)}var actions=document.getElementById('barActions');actions.innerHTML='';if(total>0){var opts=[['Оплатить наличными','CASH'],['Оплатить картой','CARD']];for(var i=0;i<opts.length;i++){var a=document.createElement('a');a.className='actionlink';a.textContent=opts[i][0];a.href='http://1c.action/BUY|'+barPopcorn+'|'+barDrink+'|0|'+opts[i][1];actions.appendChild(a)}var clear=document.createElement('button');clear.type='button';clear.className='clear-btn';clear.textContent='Очистить заказ';clear.onclick=function(){barPopcorn=0;barDrink=0;updateBar()};actions.appendChild(clear)}}
    |function esc(s){return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;')}
    |function choose(i){current=i;selected={};var s=sessions[i];document.getElementById('sessionTitle').textContent=s.name;document.getElementById('sessionInfo').textContent=s.info+' · '+s.price+' ₽';var buttons=document.querySelectorAll('.session');for(var b=0;b<buttons.length;b++)buttons[b].className='session'+(b===i?' active':'');draw()}
    |function draw(){if(current<0)return;var s=sessions[current];var h=document.getElementById('hall');h.innerHTML='';var last=null,row=null;for(var i=0;i<s.seats.length;i++){var t=s.seats[i];if(last!==t.row){last=t.row;row=document.createElement('div');row.className='seatrow';var label=document.createElement('span');label.className='rowlabel';label.textContent='Ряд '+t.row;row.appendChild(label);h.appendChild(row)}var b=document.createElement('button');b.type='button';b.className='seat '+t.status+(selected[i]?' selected':'');b.textContent=t.number;b.title='Ряд '+t.row+', место '+t.number;b.disabled=t.status==='sold';(function(n){b.onclick=function(){selected={};selected[n]=true;draw()}})(i);row.appendChild(b)}if(!s.seats.length)h.textContent='В этом зале пока нет мест';var names=[],total=0,selectedSeat=null;for(var k in selected){if(selected[k]){selectedSeat=s.seats[k];names.push('Ряд '+selectedSeat.row+', место '+selectedSeat.number);total+=s.price}}var selection=document.getElementById('selection');selection.textContent=selectedSeat&&selectedSeat.status==='booked'?'Место забронировано — бронь можно выкупить':(names.length?names.join('; ')+' — '+total+' ₽':'Места не выбраны');var acts=document.getElementById('actions');acts.innerHTML='';if(selectedSeat){var opts=[];if(selectedSeat.status==='booked'){var redeem='http://1c.action/REDEEM~'+selectedSeat.booking+'~';opts=[['Выкупить бронь наличными',redeem+'CASH'],['Выкупить бронь картой',redeem+'CARD']]}else{var base='http://1c.action/TICKET~'+s.id+'~'+selectedSeat.id+'~';opts=[['Наличные',base+'CASH'],['Банковская карта',base+'CARD'],['Забронировать на 15 минут',base+'BOOK']]}for(var a=0;a<opts.length;a++){var link=document.createElement('a');link.href=opts[a][1];link.className='actionlink';link.textContent=opts[a][0];acts.appendChild(link)}}}
    |if(sessions.length)choose(0);
    |</script></body></html>";
    Кнопки = "";
    Для Индекс = 0 По СеансыДанные.Количество() - 1 Цикл
        Сеанс = СеансыДанные[Индекс];
        Кнопки = Кнопки + "<button class='session' onclick='choose(" + Строка(Индекс) + ")'><b>"
            + ЭкранироватьHTMLКассы(Сеанс.name) + "</b><span>"
            + ЭкранироватьHTMLКассы(Сеанс.info) + "</span></button>";
    КонецЦикла;
    Если СеансыДанные.Количество() = 0 Тогда
        Кнопки = "<div class='muted'>Нет предстоящих сеансов. Создайте сеанс в справочнике 1С.</div>";
    КонецЕсли;
    Если РежимОтображения = "bar" Тогда
        HTML = СтрЗаменить(HTML, "{{TICKET_VISIBILITY}}", "display:none;");
        HTML = СтрЗаменить(HTML, "{{BAR_VISIBILITY}}", "display:block;");
        HTML = СтрЗаменить(HTML, "{{TICKET_ACTIVE}}", "");
        HTML = СтрЗаменить(HTML, "{{BAR_ACTIVE}}", "active");
    Иначе
        HTML = СтрЗаменить(HTML, "{{TICKET_VISIBILITY}}", "display:grid;");
        HTML = СтрЗаменить(HTML, "{{BAR_VISIBILITY}}", "display:none;");
        HTML = СтрЗаменить(HTML, "{{TICKET_ACTIVE}}", "active");
        HTML = СтрЗаменить(HTML, "{{BAR_ACTIVE}}", "");
    КонецЕсли;

    HTML = СтрЗаменить(HTML, "{{SESSIONS}}", Кнопки);
    HTML = СтрЗаменить(HTML, "{{DATA}}", СериализоватьСеансыКассы(СеансыДанные));
    HTML = СтрЗаменить(HTML, "{{PHOTO_POPCORN}}", HTMLФотоПопкорна);
    HTML = СтрЗаменить(HTML, "{{PHOTO_DRINK}}", HTMLФотоНапитка);
    HTML = СтрЗаменить(HTML, "{{PRICE_POPCORN}}", СтрЗаменить(Строка(ЦенаПопкорна), ",", "."));
    HTML = СтрЗаменить(HTML, "{{PRICE_DRINK}}", СтрЗаменить(Строка(ЦенаНапитка), ",", "."));
    Возврат HTML;
КонецФункции

&НаСервере
Функция ЭкранироватьHTMLКассы(Значение)
    Результат = Строка(Значение);
    Результат = СтрЗаменить(Результат, "&", "&amp;");
    Результат = СтрЗаменить(Результат, "<", "&lt;");
    Результат = СтрЗаменить(Результат, ">", "&gt;");
    Результат = СтрЗаменить(Результат, "'", "&#39;");
    Возврат Результат;
КонецФункции

&НаСервере
Функция СериализоватьСеансыКассы(Данные)
    ЗаписьJSON = Новый ЗаписьJSON;
    ЗаписьJSON.УстановитьСтроку();
    ЗаписатьJSON(ЗаписьJSON, Данные);
    Возврат ЗаписьJSON.Закрыть();
КонецФункции

// Чтение статуса без исключительной блокировки.
// Для оформления билетов по-прежнему используется проверка в модуле документа.
&НаСервере
Функция АктивнаяБроньБилетаКассы(Сеанс, Место)
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ ПЕРВЫЕ 1 Брони.Ссылка КАК Ссылка
	|ИЗ Документ.БронированиеБилета КАК Брони
	|ГДЕ Брони.Проведен = ИСТИНА
	|  И Брони.Сеанс = &Сеанс
	|  И Брони.Место = &Место
	|  И Брони.ДействуетДо > &Сейчас
	|УПОРЯДОЧИТЬ ПО Брони.Дата УБЫВ";
	Запрос.УстановитьПараметр("Сеанс", Сеанс);
	Запрос.УстановитьПараметр("Место", Место);
	Запрос.УстановитьПараметр("Сейчас", ТекущаяДата());
	Выборка = Запрос.Выполнить().Выбрать();
	Если Выборка.Следующий() Тогда Возврат Выборка.Ссылка; КонецЕсли;
	Возврат Документы.БронированиеБилета.ПустаяСсылка();
КонецФункции

&НаСервере
Функция ПродатьБроньБилетаКассыНаСервере(КомандаСтрока)
	Части = СтрРазделить(КомандаСтрока, "~", Ложь);
	Если Части.Количество() <> 3 Или (Части[2] <> "CASH" И Части[2] <> "CARD") Тогда
		Возврат "Неверные данные продажи по брони.";
	КонецЕсли;
	Попытка
		ИДБрони = Новый УникальныйИдентификатор(Части[1]);
		СсылкаБрони = Документы.БронированиеБилета.ПолучитьСсылку(ИДБрони);
		Если НЕ ЗначениеЗаполнено(СсылкаБрони) Тогда Возврат "Бронь не найдена."; КонецЕсли;
		Бронь = СсылкаБрони.ПолучитьОбъект();
		Если НЕ Бронь.Проведен Или Бронь.ДействуетДо <= ТекущаяДата() Тогда Возврат "Срок брони истёк."; КонецЕсли;
		Если Бронь.Сеанс.ДатаНачала <= ТекущаяДата() Тогда Возврат "Сеанс уже начался."; КонецЕсли;
		Продажа = Документы.ПродажаБилета.СоздатьДокумент();
		Продажа.Дата = ТекущаяДата();
		Продажа.Бронь = СсылкаБрони;
		Продажа.Сеанс = Бронь.Сеанс;
		Продажа.Место = Бронь.Место;
		Продажа.Покупатель = Бронь.Покупатель;
		Продажа.Цена = Бронь.Сеанс.ЦенаБилета;
		Продажа.СпособОплаты = ?(Части[2] = "CASH", "Наличные", "Банковская карта");
		Продажа.Записать(РежимЗаписиДокумента.Проведение);
		Если НЕ Продажа.Проведен Тогда Возврат "Билет по брони не проведён."; КонецЕсли;
		Возврат "Билет продан по брони " + Строка(СсылкаБрони) + ". Покупатель, сеанс и место взяты из брони.";
	Исключение
		Возврат "Не удалось продать билет по брони: " + ОписаниеОшибки();
	КонецПопытки;
КонецФункции

&НаСервере
Функция СтатусМестаКассы(Сеанс, Место)
    Запрос = Новый Запрос;
    Запрос.Текст =
    "ВЫБРАТЬ
    | Билеты.Регистратор КАК Регистратор,
    | Билеты.Статус КАК Статус,
    | Билеты.ДействуетДо КАК ДействуетДо
    |ИЗ РегистрСведений.Билеты КАК Билеты
    |ГДЕ Билеты.Сеанс = &Сеанс И Билеты.Место = &Место";
    Запрос.УстановитьПараметр("Сеанс", Сеанс);
    Запрос.УстановитьПараметр("Место", Место);
    Выборка = Запрос.Выполнить().Выбрать();
    ЕстьБронь = Ложь;
    Пока Выборка.Следующий() Цикл
        Если Выборка.Статус = "Продано" Тогда
            ВозвратЗапрос = Новый Запрос;
            ВозвратЗапрос.Текст =
            "ВЫБРАТЬ ПЕРВЫЕ 1 Возвраты.Ссылка
            |ИЗ Документ.ВозвратБилета КАК Возвраты
            |ГДЕ Возвраты.Продажа = &Продажа И Возвраты.Проведен";
            ВозвратЗапрос.УстановитьПараметр("Продажа", Выборка.Регистратор);
            Если ВозвратЗапрос.Выполнить().Пустой() Тогда
                Возврат "sold";
            КонецЕсли;
        ИначеЕсли Выборка.Статус = "Забронировано"
            И Выборка.ДействуетДо > ТекущаяДата() Тогда
            ЗапросВыкупа = Новый Запрос;
            ЗапросВыкупа.Текст =
            "ВЫБРАТЬ ПЕРВЫЕ 1 Продажи.Ссылка
            |ИЗ Документ.ПродажаБилета КАК Продажи
            |ГДЕ Продажи.Бронь = &Бронь И Продажи.Проведен";
            ЗапросВыкупа.УстановитьПараметр("Бронь", Выборка.Регистратор);
            Если ЗапросВыкупа.Выполнить().Пустой() Тогда
                ЕстьБронь = Истина;
            КонецЕсли;
        КонецЕсли;
    КонецЦикла;
    Если ЕстьБронь Тогда
        Возврат "booked";
    КонецЕсли;
    Возврат "free";
КонецФункции

// ЭТАП 2. Один билет за операцию. Проверки занятости выполняются при проведении документа.
&НаСервере
Функция ОформитьБилетКассыНаСервере(КомандаСтрока)
    Части = СтрРазделить(КомандаСтрока, "~", Ложь);
    Если Части.Количество() <> 4 Тогда
        Возврат "Неверная команда кассы.";
    КонецЕсли;
    Если Части[0] <> "TICKET" Тогда
        Возврат "Неизвестная операция.";
    КонецЕсли;
    Если Части[3] <> "CASH" И Части[3] <> "CARD" И Части[3] <> "BOOK" Тогда
        Возврат "Неизвестный способ оформления.";
    КонецЕсли;
    Попытка
        ИДСеанса = Новый УникальныйИдентификатор(Части[1]);
        ИДМеста = Новый УникальныйИдентификатор(Части[2]);
        Сеанс = Справочники.Сеансы.ПолучитьСсылку(ИДСеанса);
        Место = Справочники.Места.ПолучитьСсылку(ИДМеста);
        Если НЕ ЗначениеЗаполнено(Сеанс) Или НЕ ЗначениеЗаполнено(Место) Тогда
            Возврат "Не удалось определить сеанс или место.";
        КонецЕсли;
        Если Сеанс.ДатаНачала <= ТекущаяДата() Тогда
            Возврат "Сеанс уже начался.";
        КонецЕсли;
        Если Место.Зал <> Сеанс.Зал Тогда
            Возврат "Место не принадлежит залу сеанса.";
        КонецЕсли;
        Если Части[3] = "BOOK" Тогда
            Док = Документы.БронированиеБилета.СоздатьДокумент();
            Док.Дата = ТекущаяДата();
            Док.Сеанс = Сеанс;
            Док.Место = Место;
            ПокупательБрони = Справочники.Покупатели.НайтиПоНаименованию("Розничный покупатель");
            Если НЕ ЗначениеЗаполнено(ПокупательБрони) Тогда
                Возврат "Не найден покупатель «Розничный покупатель». Заполните справочник покупателей.";
            КонецЕсли;
            Док.Покупатель = ПокупательБрони;
            Срок = ТекущаяДата() + 15 * 60;
            Если Срок > Сеанс.ДатаНачала Тогда
                Срок = Сеанс.ДатаНачала;
            КонецЕсли;
            Док.ДействуетДо = Срок;
            Док.Записать(РежимЗаписиДокумента.Проведение);
            Если НЕ Док.Проведен Тогда
                Возврат "Бронь не проведена. Проверь сообщения 1С.";
            КонецЕсли;
            Ответ = "Бронь оформлена: " + Строка(Док.Ссылка) + ". Действует до " + Формат(Срок, "ДФ=dd.MM.yyyy HH:mm");
        Иначе
            Док = Документы.ПродажаБилета.СоздатьДокумент();
            Док.Дата = ТекущаяДата();
            Док.Сеанс = Сеанс;
            Док.Место = Место;
            ПокупательБрони = Справочники.Покупатели.НайтиПоНаименованию("Розничный покупатель");
            Если НЕ ЗначениеЗаполнено(ПокупательБрони) Тогда
                Возврат "Не найден покупатель «Розничный покупатель». Заполните справочник покупателей.";
            КонецЕсли;
            Док.Покупатель = ПокупательБрони;
            Док.Цена = Сеанс.ЦенаБилета;
            Если Части[3] = "CASH" Тогда
                Оплата = "Наличные";
            Иначе
                Оплата = "Банковская карта";
            КонецЕсли;
            Док.СпособОплаты = Оплата;
            Док.Записать(РежимЗаписиДокумента.Проведение);
            Если НЕ Док.Проведен Тогда
                Возврат "Продажа не проведена. Проверь сообщения 1С.";
            КонецЕсли;
            Ответ = "Билет продан: " + Строка(Док.Ссылка) + ". Сумма " + Формат(Док.Цена, "ЧДЦ=2") + " руб. Оплата: " + Оплата + ".";
        КонецЕсли;
        ОбновитьЭкранКинотеатраНаСервере();
        Возврат Ответ;
    Исключение
        Возврат "Операция не выполнена: " + ОписаниеОшибки();
    КонецПопытки;
КонецФункции






