package com.smartmarket.hrm.attendance;
import com.smartmarket.hrm.auth.AccessControl;
import com.smartmarket.hrm.auth.StaffPolicy;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
public class EvidenceController {
 private final JdbcTemplate jdbc; private final AccessControl access; private final EvidenceStorage storage;
 public EvidenceController(JdbcTemplate jdbc,AccessControl access,EvidenceStorage storage){this.jdbc=jdbc;this.access=access;this.storage=storage;}
 @GetMapping({"/uploads/evidence/{name}","/api/attendance/evidence/{name}"})
 public ResponseEntity<Resource> read(@PathVariable String name,HttpServletRequest request){
   var user=access.current(request);
   if(!name.matches("[0-9a-f]{64}\\.(jpg|png)"))throw new ResponseStatusException(HttpStatus.NOT_FOUND);
   String hash=name.substring(0,64);
   var rows=jdbc.queryForList("SELECT ar.employee_id FROM dbo.attendance_evidence ae JOIN dbo.attendance_records ar ON ar.attendance_id=ae.attendance_id WHERE ae.file_hash=?",hash);
   if(rows.isEmpty()){
     if(!storage.uploadedBy(hash,user.employeeId()))throw new ResponseStatusException(HttpStatus.NOT_FOUND);
   }else{new StaffPolicy(jdbc,access).readEmployee(request,((Number)rows.getFirst().get("employee_id")).longValue());}
   var resource=new FileSystemResource(storage.root().resolve(name));
   if(!resource.exists())throw new ResponseStatusException(HttpStatus.NOT_FOUND);
   return ResponseEntity.ok().cacheControl(CacheControl.noStore()).contentType(name.endsWith(".png")?MediaType.IMAGE_PNG:MediaType.IMAGE_JPEG).body(resource);
 }
}
