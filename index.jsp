import {Cascader, Form, Input, message, Modal, Row, Col, Card, Button, Select} from "antd";
import React, {useEffect, useState} from "react";
import {POST} from "utils/request";
import {api} from "api";
import SelectTree from "components/Select/tree";
import PropTypes from "prop-types";
import Index from "@/pages/controlStatistics/apparatus";
import service from "@/services/services";
import util from "utils/utils";

const { Option } = Select;
const BaseDataInfo = ({visible, onCancel, initialValues}) => {
    const [form] = Form.useForm();
    const {validateFields, setFieldsValue} = form;
    const [map, setMap] = useState(null);
    const [marker, setMaker] = useState(null);
    const [standName, setStandName] = useState("");
    const [cityCode, setCityCode] = useState("110000");

    useEffect(() => {
        if (!map) {
            console.log("初始化地图");
            const tMap = new AMap.Map('baseMap', {
                features: ['bg', 'road', 'point', 'building'],
                mapStyle: 'amap://styles/normal',
                center: [116.322056,39.89491],
                pitch: 50,
                zoom: 14,
                viewMode: '2D'
            });
            AMapUI.loadUI(['control/BasicControl'], function (BasicControl) {
                //缩放控件，显示Zoom值
                tMap.addControl(new BasicControl.Zoom({
                    position: 'lt',
                    showZoomNum: true
                }));
            });
            const tMarker = new AMap.Marker();

            tMap.on('click', function (ev) {
                // 触发事件的对象
                const target = ev.target;
                // 触发事件的地理坐标，AMap.LngLat 类型
                const lnglat = ev.lnglat;
                regeoCode(lnglat);
                setFieldsValue({
                    longitude: lnglat.lng,
                    latitude: lnglat.lat,
                });
                tMap.setCenter(lnglat);
                tMarker.setPosition(lnglat);
                tMap.add(tMarker);
                tMap.setFitView(tMarker);
            });

            setMap(tMap);
            setMaker(tMarker);

            if (initialValues && initialValues.subjectId) {
                console.log("初始化！！！");
                setFieldsValue({
                    areaId: initialValues.areaId,
                    subjectName: initialValues.subjectName,
                    subjectType: initialValues.subjectType,
                    longitude: initialValues.longitude,
                    latitude: initialValues.latitude,
                    contacts: initialValues.contacts,
                    address: initialValues.address,
                    phone: initialValues.phone,
                });
                setStandName(initialValues.standName);
                if(initialValues.longitude && initialValues.longitude > 0 &&
                    initialValues.latitude && initialValues.latitude > 0) {
                    const position = new AMap.LngLat(initialValues.longitude, initialValues.latitude);  // 标准写法
                    tMap.setCenter(position);
                    tMarker.setPosition(position);
                    tMap.add(tMarker);
                    tMap.setFitView(tMarker);
                }
            }
        }

    }, [map]);

    const saveInfo = () => {
        validateFields().then(values => {
            POST(api.configure.location.save, {
                ...values, subjectId: initialValues.subjectId,standName,
            }).then(data => {
                if (data) {
                    message.success("保存成功");
                    onCancel("save");
                }
            })
        })
    };

    const setMapCenterByArea = (val) => {
        POST(service.api.config.area.getOneArea, {areaId:val}).then(data => {
            if (data) {
                console.log("area:",data);
                const {record} = data;
                setStandName(data.standName);
                const position = new AMap.LngLat(record.longitude, record.latitude);  // 标准写法
                map.setCenter(position);
                setCityCode(data.mapCode);

                setFieldsValue({
                    contacts: record.contact,
                    phone: record.contactNo
                });
            }
        })
    };

    const searchSite = ()=>{
        const subjectName = form.getFieldValue('subjectName');
        if(subjectName){
            console.log("subjectName:",subjectName);
        }else{
            message.error("请输入本底名称");
            return;
        }

        AMap.plugin('AMap.Geocoder', function() {
            var geocoder = new AMap.Geocoder({
                // city 指定进行编码查询的城市，支持传入城市名、adcode 和 citycode
                city: cityCode
            });

            console.log("city:",standName+subjectName);
            geocoder.getLocation(standName+subjectName, function(status, result) {
                if (status === 'complete' && result.info === 'OK') {
                    // result中对应详细地理坐标信息
                    console.log("result:",result);
                    const lnglat = result.geocodes[0].location;

                    setFieldsValue({
                        longitude: lnglat.lng,
                        latitude: lnglat.lat,
                    });
                    regeoCode(lnglat);
                    map.setCenter(lnglat);
                    marker.setPosition(lnglat);
                    map.add(marker);
                    map.setFitView(marker);
                }else{
                    message.error("未能找到定位定位！！");
                }
            })
        });
    };

    const regeoCode = (lnglat)=>{

        AMap.plugin(["AMap.Geocoder"],function(){
            var geocoder= new AMap.Geocoder({
                city: "341200", //城市设为北京，默认：“全国”
                radius: 1000 //范围，默认：500
            });
            geocoder.getAddress(lnglat, function(status, result) {
                if (status === 'complete'&&result.regeocode) {
                    const address = result.regeocode.formattedAddress;
                    setFieldsValue({
                        address: address.replace("安徽省阜阳市","")
                    });
                }else{
                    message.error("未查询到详细地址");
                }
            });
        });


    };

    return (
        <Modal getContainer={false} visible={visible} onCancel={() => onCancel()} title={'本地数据维护'}
               onOk={() => saveInfo()} width={'90%'}>
            <Row type="flex" justify="center" gutter={[16, 16]}>
                <Col span={8}>
                    <Form form={form} labelCol={{span: 6}}>
                        <Form.Item label="行政区划" name={'areaId'} rules={[{required: true, message: '请填写'}]}>
                            <SelectTree api={api.config.area.areaTreeForPco} showSearch={true}
                                onChange={(val)=>setMapCenterByArea(val)}
                            />
                        </Form.Item>
                        <Form.Item name={'subjectName'} label={'主体名称'} rules={[{required: true, message: '请填写'}]}>
                            <Input placeholder={"请输入"}/>
                        </Form.Item>
                        <div align="right" style={{marginTop:'-10px',marginBottom:'10px'}}>
                            <Button type="primary" onClick={()=>searchSite()}>定位</Button>
                        </div>
                        <Form.Item label="本底种类" name={'subjectType'}  rules={[{required: true, message: '请填写'}]}>
                            <Select placeholder={"请选择"} allowClear
                                    showSearch
                                    optionFilterProp="children"
                                    filterOption={(input, option) =>
                                        option.children.toLowerCase().indexOf(input.toLowerCase()) >= 0
                                    }
                            >
                                {util.codeIndex.index.SUBJECT_TYPE().map(item =>
                                    <Select.Option value={item.id} key={item.id}>{item.value}</Select.Option>)}
                            </Select>
                        </Form.Item>
                        <Form.Item name={'address'} label={'详细地址'} rules={[{required: true, message: '请填写'}]}>
                            <Input placeholder={"请输入"}/>
                        </Form.Item>
                        <Form.Item name={'longitude'} label={'经度'} rules={[{required: true, message: '请填写'}]}>
                            <Input placeholder={"请输入"} readOnly={true}/>
                        </Form.Item>
                        <Form.Item name={'latitude'} label={'纬度'} rules={[{required: true, message: '请填写'}]}>
                            <Input placeholder={"请输入"} readOnly={true}/>
                        </Form.Item>
                        <Form.Item name={'contacts'} label={'联系人'}>
                            <Input placeholder={"请输入"}/>
                        </Form.Item>
                        <Form.Item name={'phone'} label={'联系电话'}>
                            <Input placeholder={"请输入"}/>
                        </Form.Item>
                    </Form>
                </Col>
                <Col span={16}>
                    <div id={"baseMap"} style = {{width: '100%', height: '100%',zIndex:10}}/>
                </Col>
            </Row>
        </Modal>
    );

};

Index.propTypes = {
    mapId: PropTypes.string,// ID
    style: PropTypes.object,// 样式
    adcode: PropTypes.number,// 行政区划id
    mapStyle: PropTypes.string,// 地图样式
    init: PropTypes.func,// 返回map
};
export default BaseDataInfo;
