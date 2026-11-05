package com.smartmarket.hrm.attendance;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import java.time.LocalDateTime;
import java.util.*;
import com.smartmarket.hrm.auth.AccessControl;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
/** GPS bắt buộc khi chấm công: thiếu tọa độ, giả lập, sai số lớn, vị trí cũ, ngoài bán kính đều bị chặn. */
class GpsValidationTest {
 private static final LocalDateTime NOW=LocalDateTime.of(2026,11,5,8,0,0);
 private static final String CLIENT="2026-11-05T08:00:00";
 private final AttendanceController c=new AttendanceController(mock(JdbcTemplate.class),new AccessControl(),mock(EvidenceStorage.class));
 private Map<String,Object> area(Double lat,Double lng){var s=new HashMap<String,Object>();s.put("area_name","Quầy thu ngân");s.put("area_latitude",lat);s.put("area_longitude",lng);s.put("radius_meters",100);return s;}
 private AttendanceController.AttendanceRequest gps(Double lat,Double lng,Double acc,String capturedAt,Boolean mocked){return new AttendanceController.AttendanceRequest(null,null,"qr",lat,lng,acc,CLIENT,"test",null,capturedAt,mocked);}
 private String code(Runnable r){return assertThrows(AttendanceException.class,r::run).code();}
 @Test void validNearbyGpsPasses(){Double d=c.checkLocation(area(10.7769,106.7009),gps(10.7770,106.7009,15.0,"2026-11-05T07:59:50",false),NOW);assertTrue(d<20);}
 @Test void missingGpsIsRejected(){assertEquals("LOCATION_REQUIRED",code(()->c.checkLocation(area(10.7769,106.7009),gps(null,null,null,null,null),NOW)));}
 @Test void mockedGpsIsRejected(){assertEquals("GPS_MOCKED",code(()->c.checkLocation(area(10.7769,106.7009),gps(10.7769,106.7009,5.0,"2026-11-05T07:59:50",true),NOW)));}
 @Test void largeAccuracyIsRejected(){assertEquals("GPS_INACCURATE",code(()->c.checkLocation(area(10.7769,106.7009),gps(10.7769,106.7009,250.0,"2026-11-05T07:59:50",false),NOW)));}
 @Test void missingAccuracyIsRejected(){assertEquals("GPS_INACCURATE",code(()->c.checkLocation(area(10.7769,106.7009),gps(10.7769,106.7009,null,"2026-11-05T07:59:50",false),NOW)));}
 @Test void staleGpsIsRejected(){assertEquals("GPS_STALE",code(()->c.checkLocation(area(10.7769,106.7009),gps(10.7769,106.7009,10.0,"2026-11-05T07:50:00",false),NOW)));}
 @Test void missingCaptureTimeIsRejected(){assertEquals("GPS_STALE",code(()->c.checkLocation(area(10.7769,106.7009),gps(10.7769,106.7009,10.0,null,false),NOW)));}
 @Test void outsideRadiusIsRejected(){assertEquals("INVALID_LOCATION",code(()->c.checkLocation(area(10.7969,106.7009),gps(10.7769,106.7009,10.0,"2026-11-05T07:59:50",false),NOW)));}
 @Test void areaWithoutCoordinatesIsRejected(){assertEquals("AREA_LOCATION_NOT_CONFIGURED",code(()->c.checkLocation(area(null,null),gps(10.7769,106.7009,10.0,"2026-11-05T07:59:50",false),NOW)));}
 @Test void invalidCoordinatesAreRejected(){assertEquals("GPS_INVALID",code(()->c.checkLocation(area(10.7769,106.7009),gps(95.0,106.7009,10.0,"2026-11-05T07:59:50",false),NOW)));}
}
