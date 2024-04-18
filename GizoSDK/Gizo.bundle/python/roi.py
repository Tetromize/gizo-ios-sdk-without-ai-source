import numpy as np
import math
#import cv2
from datetime import datetime
#from utils.lanes import num_lanes
#from scipy.optimize import curve_fit


def _poly2(x, a, b, c):
    return a * x + b * (x ** 0.5) + c

def _poly3(x, a, b, c, d):
    return a * x + b * (x ** 0.5) + c * (x ** 0.33) + d


class GetROI:
    def __init__(self, frame_size):
        self.h, self.w = frame_size
        self.cp = [160, 160]    # [h, w/2]
        self.side_bound = 88    # 350w/1280
        self.thrsh = 0.1
        self.step = 2
        self.h_free_zone = 53  # 2h/3
        self.rec_len = 1  # record length
        self.lane_point_rec = []    # lane point record
        self.wma_lane_point_rec = []
    
    def reset(self):
        temp = (self.h, self.w)
        temp_rec = self.lane_point_rec.copy()    # lane point record
        temp_wma = self.wma_lane_point_rec.copy()
        self.__init__(temp)
        self.lane_point_rec = temp_rec
        self.wma_lane_point_rec = temp_wma

    def __call__(self, rects, da_map, ll_map):
        newest_pnts = self.get_points(da_map, ll_map)
#        print("newest_pnts:", newest_pnts)
        points = self.gen_lane(newest_pnts, min_num_points=8)
        front_pnt, front_box = self.check_front(rects, points)
#        self._draw_results(img, newest_pnts, None)
#        img1 = self.draw_results(img, points, front_pnt)
#        print("roi front_pnt:", front_pnt)
#        print("roi front_box:", front_box)
        return front_pnt, front_box, self.count_lanes(ll_map)

    def get_points(self, da_map, ll_map):
        j = -1
        cng = 0
        points = []
        while cng < 4:
            self.cp[0] -= self.step
            # print(self.cp)
            # check for termination
            if self.cp[0] < self.h_free_zone and not da_map[self.cp[0], self.cp[1]]:
                cng +=1
            else:
                cng = 0
            # if on line
            if ll_map[self.cp[0], self.cp[1]]:
                # print(self.h, ": cp on red")
                break
            # check right
            xr = None
            # check the ll_map
            xr = np.argwhere(ll_map[self.cp[0], self.cp[1]:self.cp[1] + self.side_bound] == 1)
            # print(xr)
            # if nothing found check the da_map
            if not xr.any() and da_map[self.cp[0], self.cp[1]]:
                xr = np.argwhere(da_map[self.cp[0], self.cp[1]:self.cp[1] + self.side_bound] == 0)
            # if anything found find the min
            if xr.any():
                xr = self.cp[1] + np.min(xr)
            else:
                # print(self.h, ": no xr found")
                continue
            # check left
            xl = None
            # check the ll_map
            xl = np.argwhere(ll_map[self.cp[0], self.cp[1] - self.side_bound:self.cp[1]] == 1)
            # if nothing found check the da_map
            if not xl.any() and da_map[self.cp[0], self.cp[1]]:
                xl = np.argwhere(da_map[self.cp[0], self.cp[1] - self.side_bound:self.cp[1]] == 0)
            # if anything found find the min
            if xl.any():
                xl = self.cp[1] - self.side_bound + np.max(xl)
            else:
                # print(self.h, ": no xl found")
                continue
            # if reach here, we have xr and xl
            if (xr - xl) > (2 * self.side_bound):
                continue
            # consistency check and adding to the list of points
            new_register = (self.cp[0], xl, xr)
            if self.is_consistent(new_register, points, max_distance=15, last_idx=-1):    
                points.append(new_register)
                # update self.side_bound and self.cp 
                self.side_bound = max(int(0.5 * (xr - xl) * (1 + 2 * self.thrsh)), \
                    int(0.5 * (xr - xl) + 10))
                self.cp[1] = int((xr+xl)/2)
                # print(self.side_bound)
            else:
                # to make sure the initial points are not misdetected due to the bonet shape
                if len(points) < 5:
                    points.clear()
                    points.append(new_register)
                else:
                    # very unlikely to be able to continue, but ...
                    # update self.side_bound and self.cp 
                    self.side_bound = max(int(0.5 * (xr - xl) * (1 + 2 * self.thrsh)), \
                        int(0.5 * (xr - xl) + 10))
                    self.cp[1] = int((xr+xl)/2)
        # do a backward check
        if len(points):
            # set self.side_bound and self.cp 
            xl = points[0][1]
            xr = points[0][2]
            self.side_bound = int(0.5 * (xr - xl) * (1 + 2 * self.thrsh))
            self.cp[1] = int((xr+xl)/2)
            self.cp[0] = points[0][0]
            while self.cp[0] < (self.h - self.step):
                self.cp[0] += self.step
                # print(points[0], self.side_bound)
                if ll_map[self.cp[0], self.cp[1]]:
                    print("cp on red")
                    break
                # check right
                xr = None
                # check the ll_map
                xr = np.argwhere(ll_map[self.cp[0], self.cp[1]:self.cp[1] + self.side_bound] == 1)
                # print(xr)
                # if nothing found check the da_map
                if not xr.any() and da_map[self.cp[0], self.cp[1]]:
                    xr = np.argwhere(da_map[self.cp[0], self.cp[1]:self.cp[1] + self.side_bound] == 0)
                # if anything found find the min
                if xr.any():
                    xr = self.cp[1] + np.min(xr)
                else:
                    # print(self.h, ": no xr found")
                    continue
                # check left
                xl = None
                # check the ll_map
                xl = np.argwhere(ll_map[self.cp[0], self.cp[1] - self.side_bound:self.cp[1]] == 1)
                # if nothing found check the da_map
                if not xl.any() and da_map[self.cp[0], self.cp[1]]:
                    xl = np.argwhere(da_map[self.cp[0], self.cp[1] - self.side_bound:self.cp[1]] == 0)
                # if anything found find the min
                if xl.any():
                    xl = self.cp[1] - self.side_bound + np.max(xl)
                else:
                    # print(self.h, ": no xl found")
                    continue
                # if reach here, we have xr and xl
                if (xr - xl) > 2 * self.side_bound:
                    continue
                # consistency check and adding to the list of points
                new_register = (self.cp[0], xl, xr)
                if self.is_consistent(new_register, points, max_distance=15, last_idx=0):  
                    points.insert(0, new_register)
                    # print("added")
                # update self.side_bound and self.cp 
                self.side_bound = max(int(0.5 * (xr - xl) * (1 + 2 * self.thrsh)), \
                    int(0.5 * (xr - xl) + 10))
                self.cp[1] = int((xr+xl)/2)
                # print(self.side_bound)

        # print(points)
        return points

#    def _draw_results(self, img, points, front_pnt):
#        """
#        draws ego-lane candidate points (only for visualization)
#        """
#        for point in points:
#            if (point[0] >= 60) and (point[2] - point[1] >= 1):
#                cv2.circle(img, (int(point[1]),int(point[0])), 3, (0,0,0), -1)
#                cv2.circle(img, (int(point[2]),int(point[0])), 3, (255,255,255), -1)
#        if front_pnt:
#            cv2.circle(img, front_pnt, 5, (255,255,0), -1)  # front point
#        return img

#    def draw_results(self, img, points, front_pnt):
#        """
#        draws ego-lane (only for visualization)
#        """
#        for point in points:
#            if (point[0] >= 60) and (point[2] - point[1] >= 1):
#                cv2.circle(img, (int(point[1]),int(point[0])), 1, (255,0,0), -1)
#                cv2.circle(img, (int(point[2]),int(point[0])), 1, (0,255,0), -1)
#        if front_pnt:
#            cv2.circle(img, front_pnt, 5, (255,255,0), -1)  # front point
#        return img

    def count_lanes(self, ll_map):
        # return num_lanes(ll_map)
        return None

    def is_consistent(self, new_reg, points, max_distance=15, last_idx=-1):
        if len(points):
            y_last, xl_last, xr_last = points[last_idx]
            y_new, xl_new, xr_new = new_reg
            dl = math.sqrt((y_new-y_last)**2 + (xl_new-xl_last)**2)
            dr = math.sqrt((y_new-y_last)**2 + (xr_new-xr_last)**2)
            if (dl > max_distance) or (dr > max_distance):
                return False
            else:
                return True
        return False

    def _curve_fit(self, pnts):
        pnts = np.array(pnts)
        func = _poly2
        A = np.column_stack((pnts[:,0], np.sqrt(pnts[:,0]), np.ones_like(pnts[:,0])))
        popt_l, res_l, _, _ = np.linalg.lstsq(A, pnts[:,1], rcond=None)
        popt_r, res_r, _, _ = np.linalg.lstsq(A, pnts[:,2], rcond=None)
        y = np.linspace(0, self.h-1, self.h)
        xl = func(y, *popt_l)
        xr = func(y, *popt_r)
        return np.stack((y, xl, xr), axis=-1)

    def gen_lane(self, newest_pnts, min_num_points=8):
        """
        generates a stablized lane based on the last n valid lanes
        """
        if len(newest_pnts) >= min_num_points:           # consider the detected points as valid if there are more than a min num.
            cf_pnts = self._curve_fit(newest_pnts)   # points resulting from the curve fitting
            if len(self.lane_point_rec) >= self.rec_len:
                self.lane_point_rec.append(cf_pnts)     # add the new rec to the end
                self.lane_point_rec.pop(0)  # remove the first rec
            else:
                self.lane_point_rec = [cf_pnts] * self.rec_len
            # w = np.array([.05, 0.27, 0.68]) # weights
            w = np.array([1])   # weights
            self.wma_lane_point_rec = np.mean(w * self.lane_point_rec, axis=0)
        return self.wma_lane_point_rec

    def check_front(self, rects, ll_points):
#        print("check_front", rects, ll_points)
        front_pnt = None
        front_box = None
        for ll_pnt in ll_points:
            ll_pnt[2] = min(ll_pnt[2], 320)
            ll_pnt[1] = max(ll_pnt[1], 0)
            if (ll_pnt[0] >= self.h_free_zone) and (ll_pnt[2] - ll_pnt[1] >= 1):
                for rect in rects:
                    x_bmp = int((rect[0]+rect[2])/2)
                    # for the lower 1/5 of the frame, increase the threshold to avoid false detection of vehicles exiting the frame
                    ll_thrsh = int(0.15 * abs(ll_pnt[2] - ll_pnt[1])) if (ll_pnt[0] > (0.8 * self.h)) else int(0.1 * abs(ll_pnt[2] - ll_pnt[1]))  
                    if x_bmp<(ll_pnt[2]-ll_thrsh) and x_bmp>(ll_pnt[1]+ll_thrsh) and abs(rect[3]-ll_pnt[0]) < 1:
                        front_pnt = (x_bmp, int((rect[1]+rect[3])/2))
                        front_box = rect
                        break
        return front_pnt, front_box
