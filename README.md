Map<String, Object> flowInputs = new Map<String, Object>{
    'EmployerName'        => 'NRI',
    'IsExistingMember'    => true,
    'IsInsuranceSelected' => true,
    'IsProductSelected'   => false,
    'SchemeCategory'      => 'CorpPerm>=15hrs'
};
Flow.Interview fi = Flow.Interview.createInterview('AF_Get_ADL_KA_Search_Parameters', flowInputs);
fi.start();
System.debug('>>> DCFilePaths: ' + fi.getVariableValue('DCFilePaths'));
System.debug('>>> KADataCategories: ' + fi.getVariableValue('KADataCategories'));
