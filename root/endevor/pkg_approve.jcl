//XXXXXXXX JOB ST,SOPORTE,CLASS=<% $class %>,MSGCLASS=X,REGION=6M,
// NOTIFY=HARVEST,<% $surr %>
/*JOBPARM SYSAFF=SYSB                                        
//*                                                          
//     JCLLIB ORDER=BPSCM.ENDVD.LIBR.PROCLIB                 
//*                                                          
//PKGEXEC  EXEC PROCPKG                                      
//IEBGENER.SYSUT1 DD *                                              
APPROVE PACKAGE '<% $package %>'                                    
 .                                                           
/* 

