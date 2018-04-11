/* jshint -W082 */

/*
CONSTANTS
*/

var KAZPOST_API_BASE_URL = 'http://track.kazpost.kz/api/v2/';

/*
DEFINITIONS & JOBS
*/

Parse.Cloud.job('generateTestUserParcels', function(request, status) {
  var codes = ["AVIASND", "RET", "TRNRPO", "NONDLV", "ISSSC"];
  var titles = ["Чехол", "Камера", "Джинсы", "Макбук", "Футболка"];
  var userParcelIndex = 0;
  handleNextUserParcel();
  function handleNextUserParcel() {
    if (userParcelIndex >= 5) {
      status.success("Generated test user parcels successfully");
    } else {
      var code = codes[userParcelIndex];
      var title = titles[userParcelIndex];
      var Parcel = Parse.Object.extend('Parcel');
      var parcel = new Parcel();
      parcel.save({
        test: true,
        delivered: statusCodes[code] ? (statusCodes[code].title_ru === 'Вручено') : false,
        lastCheckedAt: new Date()
      }, {
        success: function(parcel) {
          var Event = Parse.Object.extend('Event');
          var event = new Event();
          event.save({
            date: new Date(),
            parcel: parcel,
            statusCode: code,
            statusDescription: statusCodes[code] ? statusCodes[code].title_ru :
              'Неизвестный статус'
          }, {
            success: function(event) {
              var userQuery = new Parse.Query(Parse.User);
              userQuery.equalTo('username', 'test');
              userQuery.first({
                success: function(user) {
                  var UserParcel = Parse.Object.extend('UserParcel');
                  var userParcel = new UserParcel();
                  userParcel.save({
                    user: user,
                    parcel: parcel,
                    events: [event],
                    title: title
                  }, {
                    success: function(userParcel) {
                      userParcelIndex++;
                      handleNextUserParcel();
                    },
                    error: status.error
                  });
                },
                error: status.error
              });
            },
            error: function(event, error) {
              status.error(error);
            }
          });
        },
        error: function(parcel, error) {
          status.error(error);
        }
      });
    }
  }
});

Parse.Cloud.job('fixDescriptions', function(request, status) {
  var eventQuery = new Parse.Query('Event');
  eventQuery.equalTo('statusDescription', 'Неизвестный статус');
  eventQuery.find({
    success: function(events) {
      var eventIndex = 0;
      handleNextEvent();
      function handleNextEvent() {
        if (eventIndex >= events.length) {
          status.success("Fixed descriptions successfully");
        } else {
          var event = events[eventIndex];
          event.save({
            statusDescription: statusCodes[event.get('statusCode')] ?
              statusCodes[event.get('statusCode')].title_ru : 'Неизвестный статус'
          }, {
            success: function(event) {
              eventIndex++;
              handleNextEvent();
            },
            error: function(event, error) {
              response.error(error);
            }
          });
        }
      }
    },
    error: status.error
  });
});

Parse.Cloud.job('updateParcels', function(request, status) {
  var parcelQuery = new Parse.Query('Parcel');
  parcelQuery.equalTo('delivered', false);
  parcelQuery.equalTo('test', false);
  var now = new Date();
  parcelQuery.lessThan('lastCheckedAt', new Date(now.getTime() -
    10 * 60 * 1000));
  parcelQuery.find({
    success: handleParcels,
    error: status.error
  });
  function handleParcels(parcels) {
    var parcelIndex = 0;
    handleNextParcel();
    function handleNextParcel() {
      if (parcelIndex >= parcels.length) {
        status.success("Updated parcels successfully");
      } else {
        var parcel = parcels[parcelIndex];
        Parse.Cloud.run('getEventsForParcel', {
          'trackingId': parcel.get('trackingId'),
          'onlyNew': 1
        }, {
          success: handleNewEvents,
          error: parcelError
        });
        function handleNewEvents(newEvents) {
          newEvents.reverse();
          if (newEvents.length === 0) {
            parcelIndex++;
            handleNextParcel();
            return;
          }
          var userParcelQuery = new Parse.Query('UserParcel');
          userParcelQuery.equalTo('parcel', parcel);
          userParcelQuery.include('user');
          userParcelQuery.find({
            success: handleUserParcels,
            error: parcelError
          });
          function handleUserParcels(userParcels) {
            var userParcelIndex = 0;
            handleNextUserParcel();
            function handleNextUserParcel() {
              if (userParcelIndex >= userParcels.length) {
                parcelIndex++;
                handleNextParcel();
              } else {
                var userParcel = userParcels[userParcelIndex];
                Parse.Cloud.run('getEventsForParcel', {
                  'trackingId': parcel.get('trackingId'),
                  'onlyNew': 0
                }, {
                  success: handleEvents,
                  error: userParcelError
                });
                function handleEvents(events) {
                  events.reverse();
                  userParcel.save({
                    events: events
                  }, {
                    success: function(userParcel) {
                      sendPushNotification(userParcel.get('user'),
                        userParcel.get('title') || parcel.get('trackingId') + ': ' +
                        newEvents[0].get('statusDescription'), {
                          success: function() {
                            console.log("Sent a push notification to user " +
                            userParcel.get('user').id);
                            userParcelIndex++;
                            handleNextUserParcel();
                          },
                          error: userParcelError
                        });
                    },
                    error: function(userParcel, error) {
                      userParcelError(error);
                    }
                  });
                }
              }
            }
            function userParcelError(error) {
              console.error(error);
              userParcelIndex++;
              handleNextUserParcel();
            }
          }
        }
        function parcelError(error) {
          console.error(error);
          parcelIndex++;
          handleNextParcel();
        }
      }
    }
  }
});

Parse.Cloud.define('getEventsForParcel', function(request, response) {
  Parse.Cloud.run('getParcel', { 'trackingId': request.params.trackingId }, {
    success: function(parcel) {
      getRawEventsForParcel(parcel.get('trackingId'), {
        success: handleRawEvents,
        error: response.error
      });
      function handleRawEvents(rawEvents) {
        var existingEvents;
        var eventsQuery = new Parse.Query('Event');
        eventsQuery.equalTo('parcel', parcel);
        eventsQuery.find({
          success: function(events) {
            existingEvents = events;
            handleNextEvent();
          },
          error: function(error) {
            handleNextEvent();
          }
        });
        var eventIndex = 0;
        var events = [];
        function handleNextEvent() {
          if (eventIndex >= rawEvents.length) {
            response.success(events);
          } else if (existingEvents) {
            var rawEvent = rawEvents[eventIndex];
            var exists = false;
            var existingEvent;
            for (var i = 0; i < existingEvents.length; i++) {
              existingEvent = existingEvents[i];
              if (existingEvent.get('statusCode') === rawEvent.status[0] &&
                existingEvent.get('zipCode') === rawEvent.zip) {
                  exists = true;
                  break;
              }
            }
            if (exists) {
              if (request.params.onlyNew === 0) {
                events.push(existingEvent);
              }
              eventIndex++;
              handleNextEvent();
            } else {
              createEvent();
            }
          } else {
            createEvent();
          }
        }
        function createEvent() {
          var rawEvent = rawEvents[eventIndex];
          var Event = Parse.Object.extend('Event');
          var event = new Event();
          event.save({
            parcel: parcel,
            date: rawEvent.date,
            city: rawEvent.city,
            name: rawEvent.name,
            zipCode: rawEvent.zip,
            statusCode: rawEvent.status[0],
            statusDescription: statusCodes[rawEvent.status[0]] ?
              statusCodes[rawEvent.status[0]].title_ru : 'Неизвестный статус'
          }, {
            success: function(event) {
              events.push(event);
              eventIndex++;
              handleNextEvent();
            },
            error: function(event, error) {
              response.error(error);
            }
          });
        }
      }
    },
    error: response.error
  });
});

Parse.Cloud.define('getParcel', function(request, response) {
  var parcelQuery = new Parse.Query('Parcel');
  parcelQuery.equalTo('trackingId', request.params.trackingId);
  parcelQuery.first({
    success: function(parcel) {
      if (parcel) {
        if (parcel.get('delivered') && parcel.get('postOffice')) {
          response.success(parcel);
        } else {
          getParcelInfo(request.params.trackingId, {
            success: function(rawParcel) {
              parcel.save({
                delivered: rawParcel.status === 'Вручено',
                lastCheckedAt: new Date(),
                postOffice: rawParcel.postOffice
              }, {
                success: response.success,
                error: function(parcel, error) {
                  response.error(error);
                }
              });
            },
            error: response.error
          });
        }
      } else {
        createParcel();
      }
    },
    error: function(error) {
      createParcel();
    }
  });
  function createParcel() {
    getParcelInfo(request.params.trackingId, {
      success: function(rawParcel) {
        var Parcel = Parse.Object.extend('Parcel');
        var parcel = new Parcel();
        parcel.save({
          test: false,
          trackingId: rawParcel.trackid,
          delivered: rawParcel.status === 'Вручено',
          lastCheckedAt: new Date(),
          postOffice: rawParcel.postOffice
        }, {
          success: response.success,
          error: function(parcel, error) {
            response.error(error);
          }
        });
      },
      error: response.error
    });
  }
});

/*
FUNCTIONS
*/

function getParcelInfo(trackingId, response) {
  Parse.Cloud.httpRequest({
    url: KAZPOST_API_BASE_URL + trackingId,
    headers: {
      'Content-Type': 'application/json;charset=utf-8'
    }
  }).then(function(httpResponse) {
    if (httpResponse.data.error) {
      response.error('Посылка ' +  trackingId + ' не найдена в системе');
    } else {
      if (httpResponse.data.status === 'Вручено' &&
        httpResponse.data.delivery.address) {
        var postOfficeQuery = new Parse.Query('PostOffice');
        postOfficeQuery.equalTo('address', httpResponse.data.delivery.address);
        postOfficeQuery.first({
          success: function(postOffice) {
            if (postOffice) {
              httpResponse.data.postOffice = postOffice;
              response.success(httpResponse.data);
            } else {
              createPostOffice();
            }
          },
          error: function(error) {
            createPostOffice();
          }
        });
        function createPostOffice() {
          var PostOffice = Parse.Object.extend('PostOffice');
          var postOffice = new PostOffice();
          var info = httpResponse.data.delivery;
          var location;
          if (info.gps[0].length > 0) {
            location = new Parse.GeoPoint({
              latitude: parseFloat(info.gps[0].replace(',', '.')),
              longitude: parseFloat(info.gps[1].replace(',', '.'))
            });
          }
          postOffice.save({
            city: info.city,
            address: info.address,
            name: info.dep_name,
            zipCode: info.postindex,
            location: location,
            phoneNumber: info.phone,
          }, {
            success: function(postOffice) {
              httpResponse.data.postOffice = postOffice;
              response.success(httpResponse.data);
            },
            error: function(postOffice, error) {
              response.error(error);
            }
          });
        }
      } else {
        response.success(httpResponse.data);
      }
    }
  }, function(httpResponse) {
    if (httpResponse.status === 404) {
      response.error('Посылка ' +  trackingId + ' не найдена в системе');
    } else {
      response.error('Что-то пошло не так. Попробуйте чуть позже');
    }
  });
}

function getRawEventsForParcel(trackingId, response) {
  Parse.Cloud.httpRequest({
    url: KAZPOST_API_BASE_URL + trackingId + '/events',
    headers: {
      'Content-Type': 'application/json;charset=utf-8'
    }
  }).then(function(httpResponse) {
    if (httpResponse.data.error) {
      response.error('Посылка ' +  trackingId + ' не найдена в системе');
    } else {
      var dateEvents = httpResponse.data.events.reverse();
      var events = [];
      for (var i = 0; i < dateEvents.length; i++) {
        var dateComps = dateEvents[i].date.match(/\d+/g);
        var dayEvents = dateEvents[i].activity;
        for (var j = 0; j < dayEvents.length; j++) {
          var event = dayEvents[j];
          var timeComps = event.time.match(/\d+/g);
          event.date = new Date(dateComps[2], dateComps[1]-1, dateComps[0],
            timeComps[0], timeComps[1]);
          event.date.setUTCHours(event.date.getUTCHours() - 6);
          events.push(event);
        }
      }
      events.sort(function(a, b) {
          a = a.date;
          b = b.date;
          return a > b ? -1 : a < b ? 1 : 0;
      }).reverse();
      response.success(events);
    }
  }, function(httpResponse) {
    if (httpResponse.status === 404) {
      response.error('Посылка ' +  trackingId + ' не найдена в системе');
    } else {
      response.error('Что-то пошло не так. Попробуйте чуть позже');
    }
  });
}

function sendPushNotification(user, message, response) {
  var installationQuery = new Parse.Query(Parse.Installation);
  installationQuery.equalTo('user', user);
  Parse.Push.send({
    where: installationQuery,
    data: {
      alert: message
    }
  }, response);
}

/*
OTHER VARIABLES
*/

var statusCodes = {
	"BOXISS_UNDO":{"title_kz":"Отмена вручения из а-я","title_ru":"Отмена вручения из а-я","onsite":1,"group":"SRTR"},
	"AVIASND":{"title_kz":"Отправка на рейс","title_ru":"Отправка на рейс","onsite":1,"group":"SRTR"},
	"AVIASND_UNDO":{"title_kz":"Отмена отправки на рейс","title_ru":"Отмена отправки на рейс","onsite":1,"group":"SRTR"},
	"BAT":{"title_kz":"Партионный прием","title_ru":"Партионный прием","onsite":1,"group":"SRTR"},
	"CUSTOM_RET":{"title_kz":"Возврат с таможни","title_ru":"Возврат с таможни","onsite":1,"group":"SRTR"},
	"CUSTSRT_SND":{"title_kz":"Выпуск с таможни(с хранения)","title_ru":"Выпуск с таможни(с хранения)","onsite":1,"group":"SRTR"},
	"CUSTSTR_RET":{"title_kz":"Возврат с таможни (с хранения)","title_ru":"Возврат с таможни (с хранения)","onsite":1,"group":"SRTR"},
	"DELAY_RET":{"title_kz":"Возврат с таможни","title_ru":"Возврат с таможни","onsite":1,"group":"SRTR"},
	"DLV":{"title_kz":"Выдача на доставку","title_ru":"Ожидает клиента","onsite":1,"group":"SRTR"},
	"DLV_POBOX":{"title_kz":"Доставка в а/я","title_ru":"Доставка в а/я","onsite":1,"group":"SRTR"},
	"DPAY":{"title_kz":"Вручено","title_ru":"Вручено","onsite":1,"group":"SRTR"},
	"ISSPAY":{"title_kz":"Вручено","title_ru":"Вручено","onsite":1,"group":"SRTR"},
	"ISSSC":{"title_kz":"Вручено","title_ru":"Вручено","onsite":1,"group":"SRTR"},
  "S_ISS":{"title_kz":"Вручено","title_ru":"Вручено","onsite":1,"group":"SRTR"},
	"NON":{"title_kz":"Не выдано","title_ru":"Не выдано","onsite":1,"group":"SRTR"},
	"NONDLV":{"title_kz":"Не доставлено","title_ru":"Не доставлено","onsite":1,"group":"SRTR"},
	"NONDLV_S":{"title_kz":"Возврат на хранение","title_ru":"Возврат на хранение","onsite":1,"group":"SRTR"},
	"NONDLV_Z":{"title_kz":"Возврат на хранение","title_ru":"Ожидает клиента, На хранение","onsite":1,"group":"SRTR"},
	"NON_S":{"title_kz":"Не выдано","title_ru":"Не выдано","onsite":1,"group":"SRTR"},
	"PRC":{"title_kz":"Поступление","title_ru":"Поступление","onsite":1,"group":"SRTR"},
	"RCP":{"title_kz":"Прием 1","title_ru":"Прием 1","onsite":1,"group":"SRTR"},
	"RCPOPS":{"title_kz":"Прием","title_ru":"Прием","onsite":1,"group":"SRTR"},
	"RDR":{"title_kz":"Досыл","title_ru":"Досыл","onsite":1,"group":"SRTR"},
	"RDRSC":{"title_kz":"Досыл","title_ru":"Досыл","onsite":1,"group":"SRTR"},
	"RDRSCSTR":{"title_kz":"Досыл","title_ru":"Досыл","onsite":1,"group":"SRTR"},
	"RET":{"title_kz":"Возврат","title_ru":"Возврат","onsite":1,"group":"SRTR"},
	"RETSC":{"title_kz":"Возврат","title_ru":"Возврат","onsite":1,"group":"SRTR"},
	"RETSCSTR":{"title_kz":"Возврат","title_ru":"Возврат","onsite":1,"group":"SRTR"},
	"RPODELAY":{"title_kz":"Задержка на таможенном досмотре","title_ru":"Задержка на таможенном досмотре","onsite":1,"group":"SRTR"},
	"SND":{"title_kz":"Отправка","title_ru":"Отправка","onsite":1,"group":"SRTR"},
	"SNDDELAY":{"title_kz":"Выпуск задержанного  из  таможенного досмотра на возврат","title_ru":"Выпуск задержанного  из  таможенного досмотра на возврат","onsite":1,"group":"SRTR"},
	"SNDZONE":{"title_kz":"Поступление на участок сортировки","title_ru":"Поступление на участок сортировки","onsite":1,"group":"SRTR"},
	"SNDZONE_T":{"title_kz":"Выпущено таможней","title_ru":"Выпущено таможней","onsite":1,"group":"SRTR"},
	"SRTRPOREG":{"title_kz":"Сортировка","title_ru":"Сортировка","onsite":1,"group":"SRTR"},
	"SRTSND":{"title_kz":"Отправка транспорта из сортцентра","title_ru":"Отправка из участка сортировки","onsite":1,"group":"SRTR"},
	"SRTSNDB":{"title_kz":"Отправка из СЦ","title_ru":"Отправка из СЦ","onsite":1,"group":"SRTR"},
	"SRTSNDB_UNDO":{"title_kz":"Отмена отправки","title_ru":"Отмена отправки","onsite":1,"group":"SRTR"},
	"SRTSNDIM":{"title_kz":"Отправка из СЦ","title_ru":"Отправка из СЦ","onsite":1,"group":"SRTR"},
	"SRTSNDIM_UNDO":{"title_kz":"Отмена отправки","title_ru":"Отмена отправки","onsite":1,"group":"SRTR"},
	"SRTSND_UNDO":{"title_kz":"Отмена отправки транспорта","title_ru":"Отмена отправки транспорта","onsite":1,"group":"SRTR"},
	"SRT_CUSTOM":{"title_kz":"Передано таможне","title_ru":"Передано таможне","onsite":1,"group":"SRTR"},
	"STR":{"title_kz":"Хранение","title_ru":"Хранение","onsite":1,"group":"SRTR"},
	"STRSC":{"title_kz":"Возврат с хранения","title_ru":"Возврат с хранения","onsite":1,"group":"SRTR"},
	"TRNRPO":{"title_kz":"Прибытие","title_ru":"Прибытие","onsite":1,"group":"SRTR"},
	"TRNSRT":{"title_kz":"Прибытие транспорта в сортцентр","title_ru":"Прибытие транспорта в сортцентр","onsite":1,"group":"SRTR"},

	"BOXISS":{"title_kz":"Вручение из а/я","title_ru":"Вручение из а/я","onsite":0,"group":"SRTR"},
	"DEL_STR":{"title_kz":"Удаление с хранения","title_ru":"Удаление с хранения","onsite":0,"group":"SRTR"},
	"DLV_POBOX_UNDO":{"title_kz":"Отмена доставки в а/я","title_ru":"Отмена доставки в а/я","onsite":0,"group":"SRTR"},
	"DLV_UNDO":{"title_kz":"Отмена доставки","title_ru":"Отмена доставки","onsite":0,"group":"SRTR"},
	"NONTRNOPS":{"title_kz":"Неприбытие","title_ru":"Неприбытие","onsite":0,"group":"SRTR"},
	"NONTRNSRT":{"title_kz":"Неприбытие","title_ru":"Неприбытие","onsite":0,"group":"SRTR"},
	"PRNNTC2_UNDO":{"title_kz":"Отмена  хранения","title_ru":"Отмена  хранения","onsite":0,"group":"SRTR"},
	"RDRSCSTR_UNDO":{"title_kz":"Отмена досыла с хранения в СЦ","title_ru":"Отмена досыла с хранения в СЦ","onsite":0,"group":"SRTR"},
	"RDRSC_UNDO":{"title_kz":"Отмена досыла в СЦ","title_ru":"Отмена досыла в СЦ","onsite":0,"group":"SRTR"},
	"RDR_UNDO":{"title_kz":"Отмена досыла","title_ru":"Отмена досыла","onsite":0,"group":"SRTR"},
	"REGPBT":{"title_kz":"Регистрация на участке","title_ru":"Регистрация на участке","onsite":0,"group":"SRTR"},
	"REGPBT_UNDO":{"title_kz":"Отмена регистрации","title_ru":"Отмена регистрации","onsite":0,"group":"SRTR"},
	"REGSRT":{"title_kz":"Регистрация на участке","title_ru":"Регистрация на участке","onsite":0,"group":"SRTR"},
	"REGSRT_UNDO":{"title_kz":"Отмена регистрации","title_ru":"Отмена регистрации","onsite":0,"group":"SRTR"},
	"RETSCSTR_UNDO":{"title_kz":"Отмена возврата с хранения в СЦ","title_ru":"Отмена возврата с хранения в СЦ","onsite":0,"group":"SRTR"},
	"RETSC_UNDO":{"title_kz":"Отмена возврата в СЦ","title_ru":"Отмена возврата в СЦ","onsite":0,"group":"SRTR"},
	"RET_UNDO":{"title_kz":"Отмена возврата","title_ru":"Отмена возврата","onsite":0,"group":"SRTR"},
	"RPODELAY_UNDO":{"title_kz":"Отмена задержки РПО","title_ru":"Отмена задержки РПО","onsite":0,"group":"SRTR"},
	"SNDDELAY_UNDO":{"title_kz":"Отмена выпуска задержанного","title_ru":"Отмена выпуска задержанного","onsite":0,"group":"SRTR"},
	"SNDZONE_T_UNDO":{"title_kz":"Отмена выпуска из участка ТК","title_ru":"Отмена выпуска из участка ТК","onsite":0,"group":"SRTR"},
	"SNDZONE_UNDO":{"title_kz":"Отмена передачи в зону сортировки","title_ru":"Отмена передачи в зону сортировки","onsite":0,"group":"SRTR"},
	"SRTRPOREG_UNDO":{"title_kz":"Отмена приписки к емкости (документу)","title_ru":"Отмена приписки к емкости (документу)","onsite":0,"group":"SRTR"},
	"SRT_CUSTOM_UNDO":{"title_kz":"Отмена передачи на таможенный контроль","title_ru":"Отмена передачи на таможенный контроль","onsite":0,"group":"SRTR"},
	"STRCUST":{"title_kz":"Передать на хранение","title_ru":"Передать на хранение","onsite":0,"group":"SRTR"},
	"STRCUST_UNDO":{"title_kz":"Отмена передачи на хранение","title_ru":"Отмена передачи на хранение","onsite":0,"group":"SRTR"},
	"TRN":{"title_kz":"Прибытие транспорта","title_ru":"Прибытие транспорта","onsite":0,"group":"SRTR"},
	"TRNBAG":{"title_kz":"Прибытие емкости","title_ru":"Прибытие емкости","onsite":0,"group":"SRTR"},
	"TRNSRT_UNDO":{"title_kz":"Отмена прибытия","title_ru":"Отмена прибытия","onsite":0,"group":"SRTR"},
	"TRN_UNDO":{"title_kz":"Отмена прибытия транспорта","title_ru":"Отмена прибытия транспорта","onsite":0,"group":"SRTR"},
	"CORRECT":{"title_kz":"Операция корректировки CORRECT","title_ru":"Корректировка данных отправления", "onsite":0,"group":"SRTR"},
	"EME":{"title_kz":"Отправление задержано на таможне", "title_ru":"Отправление задержано на таможне"},
	"EDA":{"title_kz":"Находится на входящем участке обмена", "title_ru":" Находится на входящем участке обмена"},
	"EDB":{"title_kz":"Отправление предъявлено таможне", "title_ru":"Отправление предъявлено таможне"},
	"EDC":{"title_kz":"Отправление возвращено из таможни", "title_ru":"Отправление возвращено из таможни"},
	"EDD":{"title_kz":"Отправление поступило в промежуточный сортировочный центр", "title_ru":"Отправление поступило в промежуточный сортировочный центр"},
	"EDE":{"title_kz":"Отправление покинуло промежуточный сортировочный центр", "title_ru":"Отправление покинуло промежуточный сортировочный центр"},
	"EDF":{"title_kz":"Отправление в пункте доставки на хранении", "title_ru":"Отправление в пункте доставки на хранении"},
	"EDG":{"title_kz":"Отправление передано почтальону/курьеру на доставку", "title_ru":"Отправление передано почтальону/курьеру на доставку"},
	"EDH":{"title_kz":"Отправление поступило в пункт самовывоза", "title_ru":"Отправление поступило в пункт самовывоза"},
	"EDX":{"title_kz":"Отправление задержано контролирующими органами", "title_ru":"Отправление задержано контролирующими органами"},
	"EMA":{"title_kz":"Прием отправления", "title_ru":"Прием отправления"},
	"EMB":{"title_kz":"Отправление прибыло в промежуточный пункт обмена", "title_ru":"Отправление прибыло в промежуточный пункт обмена"},
	"EMC":{"title_kz":"Отрпавление покинуло промежуточный сортцентр", "title_ru":"Отрпавление покинуло промежуточный сортцентр"},
	"EMD":{"title_kz":"Отправление прибыло в промежуточный пункт обмена", "title_ru":"Отправление прибыло в промежуточный пункт обмена"},
	"EMF":{"title_kz":"Отправление покинуло пункт обмена в стране получателя", "title_ru":"Отправление покинуло пункт обмена в стране получателя"},
	"EMG":{"title_kz":"Отправление прибыло в пункт выдачи", "title_ru":"Отправление прибыло в пункт выдачи"},
	"EMH":{"title_kz":"Доставка отправления почтальоном/курьером не состоялась", "title_ru":"Доставка отправления почтальоном/курьером не состоялась"},
	"EMI":{"title_kz":"Отправление успешно доставлено", "title_ru":"Отправление успешно доставлено"},
	"EMJ":{"title_kz":"Прибытие в транзитный пункт обмена", "title_ru":"Прибытие в транзитный пункт обмена"},
	"EXA":{"title_kz":"Отправление передано на таможню страны отправителя", "title_ru":"Отправление передано на таможню страны отправителя"},
	"EXB":{"title_kz":"Отправление получено таможней страны отправителя", "title_ru":"Отправление получено таможней страны отправителя"},
	"EXC":{"title_kz":"Отправление успешно прошло таможенный контроль", "title_ru":"Отправление успешно прошло таможенный контроль"},
	"EXD":{"title_kz":"Отправление задержано в пункте обмена", "title_ru":"Отправление задержано в пункте обмена"},
	"EXX":{"title_kz":"Отправка исходящего отправления отменена", "title_ru":"Отправка исходящего отправления отменена"},
	"TRNPST":{"title_kz":"Прибытие в постамат","title_ru": "Прибытие в постамат","onsite":1,"group":"SRTR"},
	"STRPST":{"title_kz":"Хранение в постамате","title_ru": "Хранение в постамате","onsite":1,"group":"SRTR"},
	"RETPST":{"title_kz":"Выемка из постамата","title_ru": "Выемка из постамата","onsite":1,"group":"SRTR"},
	"TRANSITRCV":{"title_kz":"Прибытие в СЦ(транзит)", "title_ru":"Прибытие в СЦ(транзит)", "onsite":1,"group":"SRTR"},
	"TRANSITSND":{"title_kz":"Отправка из СЦ(транзит)", "title_ru":"Отправка из СЦ(транзит)", "onsite":1,"group":"SRTR"}
};
