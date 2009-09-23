//XXXXXXXX JOB ST,SOPORTE,CLASS=<% $class %>,MSGCLASS=X,REGION=6M,      
//         NOTIFY=&SYSUID                                    
/*JOBPARM SYSAFF=SYSB                                        
//*                                                          
//     JCLLIB ORDER=BPSCM.ENDVD.LIBR.PROCLIB                 
//*                                                          
//PKGEXEC  EXEC PROCPKG                                      
//IEBGENER.SYSUT1 DD *                                              
EXECUTE PACKAGE '<% $package %>'                                    
 .                                                           
/* 

